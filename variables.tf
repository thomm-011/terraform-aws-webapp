# ===============================================
# VARIABLES CONFIGURATION
# ===============================================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "thomas-webapp"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# ===============================================
# NETWORKING VARIABLES
# ===============================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_count" {
  description = "Number of public subnets"
  type        = number
  default     = 2

  validation {
    condition     = var.public_subnet_count >= 2 && var.public_subnet_count <= 4
    error_message = "Public subnet count must be between 2 and 4."
  }
}

variable "private_subnet_count" {
  description = "Number of private subnets"
  type        = number
  default     = 2

  validation {
    condition     = var.private_subnet_count >= 2 && var.private_subnet_count <= 4
    error_message = "Private subnet count must be between 2 and 4."
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

# ===============================================
# COMPUTE VARIABLES
# ===============================================

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 6
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}

variable "key_name" {
  description = "AWS Key Pair name for EC2 instances"
  type        = string
  default     = ""
}

# ===============================================
# DATABASE VARIABLES
# ===============================================

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "webapp"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "db_allocated_storage" {
  description = "Database allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_backup_retention_period" {
  description = "Database backup retention period in days"
  type        = number
  default     = 7
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = false
}

# ===============================================
# STORAGE VARIABLES
# ===============================================

variable "s3_bucket_name" {
  description = "S3 bucket name for static assets"
  type        = string
  default     = ""
}

variable "enable_s3_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

# ===============================================
# MONITORING VARIABLES
# ===============================================

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for EC2 instances"
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "Health check path for ALB"
  type        = string
  default     = "/"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

# ===============================================
# TAGS VARIABLES
# ===============================================

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
