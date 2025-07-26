# ===============================================
# OUTPUTS
# ===============================================

# ===============================================
# NETWORKING OUTPUTS
# ===============================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[*].id : []
}

# ===============================================
# SECURITY OUTPUTS
# ===============================================

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "web_security_group_id" {
  description = "ID of the web servers security group"
  value       = aws_security_group.web.id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

# ===============================================
# COMPUTE OUTPUTS
# ===============================================

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.web.arn
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.arn
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.web.id
}

# ===============================================
# DATABASE OUTPUTS
# ===============================================

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "database_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "database_username" {
  description = "Database username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "database_password" {
  description = "Database password"
  value       = aws_db_instance.main.password
  sensitive   = true
}

output "database_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.main.arn
}

output "db_subnet_group_name" {
  description = "Database subnet group name"
  value       = aws_db_subnet_group.main.name
}

# ===============================================
# STORAGE OUTPUTS
# ===============================================

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.assets.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.assets.arn
}

output "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.assets.bucket_domain_name
}

# ===============================================
# SECRETS OUTPUTS
# ===============================================

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "secrets_manager_secret_name" {
  description = "Name of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.db_credentials.name
}

# ===============================================
# IAM OUTPUTS
# ===============================================

output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

# ===============================================
# MONITORING OUTPUTS
# ===============================================

output "cloudwatch_alarms" {
  description = "CloudWatch alarm names"
  value = {
    high_cpu = aws_cloudwatch_metric_alarm.high_cpu.alarm_name
    low_cpu  = aws_cloudwatch_metric_alarm.low_cpu.alarm_name
  }
}

# ===============================================
# APPLICATION OUTPUTS
# ===============================================

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "health_check_url" {
  description = "URL for health check endpoint"
  value       = "http://${aws_lb.main.dns_name}/health.php"
}

# ===============================================
# SUMMARY OUTPUT
# ===============================================

output "deployment_summary" {
  description = "Summary of the deployed infrastructure"
  value = {
    project_name    = var.project_name
    environment     = var.environment
    region          = var.aws_region
    vpc_id          = aws_vpc.main.id
    public_subnets  = length(aws_subnet.public)
    private_subnets = length(aws_subnet.private)
    database_engine = aws_db_instance.main.engine
    s3_bucket       = aws_s3_bucket.assets.bucket
    application_url = "http://${aws_lb.main.dns_name}"
    deployed_by     = "Thomas Silva Cordeiro"
    deployment_date = timestamp()
  }
}
