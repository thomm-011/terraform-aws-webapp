#!/bin/bash

# ===============================================
# EC2 User Data Script
# Author: Thomas Silva Cordeiro
# Description: Bootstrap script for web servers
# ===============================================

# Update system
yum update -y

# Install required packages
yum install -y httpd mysql php php-mysql aws-cli

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Configure Apache
cat > /var/www/html/index.php << 'EOF'
<?php
$db_endpoint = "${db_endpoint}";
$s3_bucket = "${s3_bucket}";
$region = "${region}";
$instance_id = file_get_contents('http://169.254.169.254/latest/meta-data/instance-id');
$availability_zone = file_get_contents('http://169.254.169.254/latest/meta-data/placement/availability-zone');

echo "<h1>Thomas Silva Cordeiro - Web Application</h1>";
echo "<h2>Infrastructure deployed with Terraform</h2>";
echo "<hr>";
echo "<p><strong>Instance ID:</strong> " . $instance_id . "</p>";
echo "<p><strong>Availability Zone:</strong> " . $availability_zone . "</p>";
echo "<p><strong>Database Endpoint:</strong> " . $db_endpoint . "</p>";
echo "<p><strong>S3 Bucket:</strong> " . $s3_bucket . "</p>";
echo "<p><strong>Region:</strong> " . $region . "</p>";
echo "<hr>";
echo "<p><em>Deployed by Thomas Silva Cordeiro using Terraform</em></p>";

// Test database connection
$servername = explode(":", $db_endpoint)[0];
$username = "admin";
$dbname = "webapp";

try {
    // Note: In production, use AWS Secrets Manager to retrieve password
    echo "<h3>Database Connection Status:</h3>";
    echo "<p style='color: orange;'>Connection test disabled for security. Use AWS Secrets Manager in production.</p>";
} catch(Exception $e) {
    echo "<p style='color: red;'>Database connection failed: " . $e->getMessage() . "</p>";
}

// Display system information
echo "<h3>System Information:</h3>";
echo "<p><strong>PHP Version:</strong> " . phpversion() . "</p>";
echo "<p><strong>Server Time:</strong> " . date('Y-m-d H:i:s') . "</p>";
echo "<p><strong>Load Average:</strong> " . sys_getloadavg()[0] . "</p>";
?>
EOF

# Create health check endpoint
cat > /var/www/html/health.php << 'EOF'
<?php
header('Content-Type: application/json');
echo json_encode([
    'status' => 'healthy',
    'timestamp' => date('c'),
    'instance_id' => file_get_contents('http://169.254.169.254/latest/meta-data/instance-id')
]);
?>
EOF

# Set proper permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Configure CloudWatch agent (optional)
yum install -y amazon-cloudwatch-agent

# Create CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "metrics": {
        "namespace": "Thomas/WebApp",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/httpd/access_log",
                        "log_group_name": "/thomas/webapp/apache/access",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/log/httpd/error_log",
                        "log_group_name": "/thomas/webapp/apache/error",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Create a simple monitoring script
cat > /usr/local/bin/webapp-monitor.sh << 'EOF'
#!/bin/bash
# Simple monitoring script

# Check if Apache is running
if ! systemctl is-active --quiet httpd; then
    echo "$(date): Apache is not running, attempting to restart" >> /var/log/webapp-monitor.log
    systemctl restart httpd
fi

# Check disk usage
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "$(date): Disk usage is high: $${DISK_USAGE}%" >> /var/log/webapp-monitor.log
fi

# Send custom metric to CloudWatch
aws cloudwatch put-metric-data \
    --region ${region} \
    --namespace "Thomas/WebApp/Custom" \
    --metric-data MetricName=DiskUsage,Value=$DISK_USAGE,Unit=Percent
EOF

chmod +x /usr/local/bin/webapp-monitor.sh

# Add monitoring script to crontab
echo "*/5 * * * * /usr/local/bin/webapp-monitor.sh" | crontab -

# Create log rotation for custom logs
cat > /etc/logrotate.d/webapp << 'EOF'
/var/log/webapp-monitor.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF

# Final restart of services
systemctl restart httpd
systemctl restart crond

# Log completion
echo "$(date): User data script completed successfully" >> /var/log/webapp-bootstrap.log
