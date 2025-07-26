# 🚀 AWS Web Application Infrastructure with Terraform

**Author:** Thomas Silva Cordeiro  
**Project:** Scalable Web Application Infrastructure  
**Technology:** Terraform + AWS  

## 📋 Overview

This project demonstrates a complete, production-ready AWS infrastructure for a scalable web application using Terraform. It showcases best practices in Infrastructure as Code (IaC), security, monitoring, and cost optimization.

## 🏗️ Architecture

### **High-Level Architecture**
```
Internet → ALB → Auto Scaling Group (EC2) → RDS MySQL
                      ↓
                   S3 Bucket (Assets)
                      ↓
                CloudWatch (Monitoring)
```

### **Detailed Components**
- **VPC** with public and private subnets across multiple AZs
- **Application Load Balancer** for high availability
- **Auto Scaling Group** with EC2 instances
- **RDS MySQL** database with Multi-AZ option
- **S3 bucket** for static assets
- **CloudWatch** monitoring and alarms
- **IAM roles** with least privilege access
- **Security Groups** with proper network segmentation

## 🛠️ Resources Created

### **Networking (12+ resources)**
- 1 VPC with DNS support
- 2 Public subnets (multi-AZ)
- 2 Private subnets (multi-AZ)
- 1 Internet Gateway
- 2 NAT Gateways (optional)
- Route tables and associations
- 3 Security Groups (ALB, Web, Database)

### **Compute (8+ resources)**
- Application Load Balancer
- Target Group with health checks
- Launch Template with user data
- Auto Scaling Group (2-6 instances)
- Auto Scaling Policies (scale up/down)
- CloudWatch Alarms (CPU monitoring)
- IAM Role and Instance Profile

### **Database (5+ resources)**
- RDS MySQL instance
- DB Subnet Group
- DB Parameter Group
- Enhanced Monitoring
- Secrets Manager for credentials

### **Storage & Security (6+ resources)**
- S3 bucket with encryption
- Bucket policies and lifecycle
- IAM roles and policies
- CloudWatch Log Groups
- Random password generation

## 📊 Features

### **🔒 Security**
- ✅ Private subnets for database and compute
- ✅ Security groups with minimal required access
- ✅ S3 bucket encryption and access controls
- ✅ IAM roles with least privilege
- ✅ Database credentials in Secrets Manager
- ✅ No hardcoded passwords

### **📈 Scalability**
- ✅ Auto Scaling Group (2-6 instances)
- ✅ Application Load Balancer
- ✅ Multi-AZ deployment
- ✅ CloudWatch-based scaling policies
- ✅ RDS with auto-scaling storage

### **🔍 Monitoring**
- ✅ CloudWatch alarms for CPU utilization
- ✅ Enhanced RDS monitoring
- ✅ Application health checks
- ✅ Custom metrics and logging
- ✅ Performance Insights for RDS

### **💰 Cost Optimization**
- ✅ t3.micro instances (free tier eligible)
- ✅ Configurable NAT Gateway (can disable for dev)
- ✅ S3 lifecycle policies
- ✅ Proper resource tagging
- ✅ Auto Scaling to match demand

## 🚀 Quick Start

### **Prerequisites**
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 installed
- AWS account with sufficient permissions

### **1. Clone and Configure**
```bash
# Navigate to project directory
cd terraform-aws-webapp

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit variables according to your needs
nano terraform.tfvars
```

### **2. Deploy Infrastructure**
```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### **3. Access Your Application**
```bash
# Get the application URL
terraform output application_url

# Example output: http://thomas-webapp-alb-123456789.us-east-1.elb.amazonaws.com
```

### **4. Clean Up**
```bash
# Destroy all resources
terraform destroy
```

## ⚙️ Configuration

### **Essential Variables**
```hcl
# terraform.tfvars
aws_region   = "us-east-1"
project_name = "thomas-webapp"
environment  = "dev"

# Instance configuration
instance_type    = "t3.micro"
desired_capacity = 2

# Database configuration
db_instance_class = "db.t3.micro"
db_multi_az      = false  # Set to true for production

# Cost optimization
enable_nat_gateway = false  # Set to true for production
```

### **Cost Considerations**
| Resource | Monthly Cost (approx.) | Notes |
|----------|----------------------|-------|
| EC2 (2x t3.micro) | $0 - $16 | Free tier eligible |
| RDS (db.t3.micro) | $0 - $15 | Free tier eligible |
| NAT Gateway | $45 each | Can disable for dev |
| ALB | $22 | Always required |
| **Total (dev)** | **$22 - $98** | Depending on configuration |

## 📁 Project Structure

```
terraform-aws-webapp/
├── main.tf                    # Main configuration and networking
├── variables.tf               # Variable definitions
├── compute.tf                 # EC2, ASG, ALB resources
├── database.tf               # RDS and S3 resources
├── outputs.tf                # Output values
├── user_data.sh              # EC2 bootstrap script
├── terraform.tfvars.example  # Example configuration
└── README.md                 # This file
```

## 🔧 Customization

### **Adding SSL/HTTPS**
```hcl
# Add to variables.tf
variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
  default     = ""
}

# Add HTTPS listener in compute.tf
resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
```

### **Adding CloudFront CDN**
```hcl
resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "ALB-${var.project_name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled = true
  
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "ALB-${var.project_name}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
```

## 🔍 Monitoring and Troubleshooting

### **Key Metrics to Monitor**
- EC2 CPU Utilization (Auto Scaling triggers)
- ALB Request Count and Response Time
- RDS CPU and Connection Count
- S3 Request Metrics

### **Common Issues**
1. **Health Check Failures**
   - Check security group rules
   - Verify application is running on port 80
   - Check health check path configuration

2. **Database Connection Issues**
   - Verify security group allows port 3306
   - Check database credentials in Secrets Manager
   - Ensure RDS is in private subnets

3. **High Costs**
   - Disable NAT Gateway for development
   - Use smaller instance types
   - Monitor CloudWatch billing alarms

## 🎯 Learning Outcomes

This project demonstrates:
- **Infrastructure as Code** best practices
- **AWS Well-Architected Framework** principles
- **Security** implementation in cloud environments
- **Cost optimization** strategies
- **Monitoring and observability** setup
- **Terraform** advanced features and modules

## 🚀 Next Steps

### **Enhancements**
- [ ] Add CloudFront CDN
- [ ] Implement SSL/TLS certificates
- [ ] Add ElastiCache for caching
- [ ] Implement CI/CD pipeline
- [ ] Add container support (ECS/EKS)
- [ ] Implement backup strategies
- [ ] Add disaster recovery

### **Advanced Features**
- [ ] Multi-region deployment
- [ ] Blue-green deployments
- [ ] Infrastructure testing
- [ ] Cost monitoring and alerts
- [ ] Security scanning integration

## 📞 Contact

**Thomas Silva Cordeiro**
- **Email:** thomas.s.cordeiro@hotmail.com
- **LinkedIn:** [thomas-s-923082184](https://www.linkedin.com/in/thomas-s-923082184/)
- **GitHub:** [thomm-011](https://github.com/thomm-011)

---

**💡 "Infrastructure as Code: Building scalable, secure, and cost-effective cloud solutions with Terraform and AWS."**

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🙏 Acknowledgments

- AWS Documentation and Best Practices
- Terraform AWS Provider Documentation
- AWS Well-Architected Framework
- Community best practices and examples
