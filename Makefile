# ===============================================
# Terraform AWS Web Application - Makefile
# Author: Thomas Silva Cordeiro
# ===============================================

.PHONY: help init plan apply destroy validate format check clean status outputs

# Default target
help: ## Show this help message
	@echo "🚀 Terraform AWS Web Application"
	@echo "Author: Thomas Silva Cordeiro"
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform
	@echo "🔧 Initializing Terraform..."
	terraform init
	@echo "✅ Terraform initialized successfully!"

validate: ## Validate Terraform configuration
	@echo "🔍 Validating Terraform configuration..."
	terraform validate
	@echo "✅ Configuration is valid!"

format: ## Format Terraform files
	@echo "📝 Formatting Terraform files..."
	terraform fmt -recursive
	@echo "✅ Files formatted successfully!"

plan: ## Create Terraform execution plan
	@echo "📋 Creating Terraform execution plan..."
	terraform plan -out=tfplan
	@echo "✅ Plan created successfully! Review above and run 'make apply' to proceed."

apply: ## Apply Terraform configuration
	@echo "🚀 Applying Terraform configuration..."
	@if [ -f tfplan ]; then \
		terraform apply tfplan; \
		rm -f tfplan; \
	else \
		echo "❌ No plan file found. Run 'make plan' first."; \
		exit 1; \
	fi
	@echo "✅ Infrastructure deployed successfully!"
	@echo ""
	@echo "🌐 Application URL:"
	@terraform output -raw application_url
	@echo ""

destroy: ## Destroy Terraform infrastructure
	@echo "⚠️  This will destroy ALL infrastructure!"
	@echo "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo "🗑️  Destroying infrastructure..."
	terraform destroy
	@echo "✅ Infrastructure destroyed successfully!"

status: ## Show current infrastructure status
	@echo "📊 Current Infrastructure Status:"
	@echo "=================================="
	@terraform show -json | jq -r '.values.root_module.resources[] | select(.type != "random_password" and .type != "random_id") | "\(.type): \(.values.tags.Name // .address)"' 2>/dev/null || echo "No infrastructure deployed or jq not installed"

outputs: ## Show Terraform outputs
	@echo "📤 Terraform Outputs:"
	@echo "===================="
	@terraform output

check: validate format ## Run validation and formatting checks
	@echo "🔍 Running security checks..."
	@if command -v tfsec >/dev/null 2>&1; then \
		tfsec .; \
	else \
		echo "⚠️  tfsec not installed. Install with: brew install tfsec"; \
	fi
	@echo "✅ All checks completed!"

clean: ## Clean temporary files
	@echo "🧹 Cleaning temporary files..."
	rm -f tfplan
	rm -f terraform.tfstate.backup
	rm -rf .terraform.lock.hcl
	@echo "✅ Cleanup completed!"

cost: ## Estimate infrastructure costs (requires infracost)
	@echo "💰 Estimating infrastructure costs..."
	@if command -v infracost >/dev/null 2>&1; then \
		infracost breakdown --path .; \
	else \
		echo "⚠️  infracost not installed. Install from: https://www.infracost.io/docs/"; \
	fi

setup: ## Setup development environment
	@echo "🛠️  Setting up development environment..."
	@if [ ! -f terraform.tfvars ]; then \
		cp terraform.tfvars.example terraform.tfvars; \
		echo "📝 Created terraform.tfvars from example. Please edit it with your values."; \
	else \
		echo "✅ terraform.tfvars already exists."; \
	fi
	@echo "🔧 Checking required tools..."
	@command -v terraform >/dev/null 2>&1 || (echo "❌ Terraform not installed" && exit 1)
	@command -v aws >/dev/null 2>&1 || (echo "❌ AWS CLI not installed" && exit 1)
	@aws sts get-caller-identity >/dev/null 2>&1 || (echo "❌ AWS credentials not configured" && exit 1)
	@echo "✅ Development environment ready!"

graph: ## Generate dependency graph
	@echo "📊 Generating dependency graph..."
	terraform graph | dot -Tpng > infrastructure-graph.png
	@echo "✅ Graph saved as infrastructure-graph.png"

docs: ## Generate documentation
	@echo "📚 Generating documentation..."
	@if command -v terraform-docs >/dev/null 2>&1; then \
		terraform-docs markdown table . > TERRAFORM_DOCS.md; \
		echo "✅ Documentation generated in TERRAFORM_DOCS.md"; \
	else \
		echo "⚠️  terraform-docs not installed. Install from: https://terraform-docs.io/"; \
	fi

# Development workflow targets
dev-deploy: setup init plan apply ## Complete development deployment workflow

dev-destroy: destroy clean ## Complete development cleanup workflow

# Production-like workflow
prod-check: check ## Run all checks for production deployment
	@echo "🔒 Running additional production checks..."
	@grep -q 'db_multi_az.*=.*true' terraform.tfvars || echo "⚠️  Consider enabling db_multi_az for production"
	@grep -q 'enable_nat_gateway.*=.*true' terraform.tfvars || echo "⚠️  Consider enabling NAT Gateway for production"
	@echo "✅ Production checks completed!"

# Monitoring and maintenance
logs: ## Show recent CloudWatch logs (requires AWS CLI)
	@echo "📋 Recent application logs:"
	@aws logs describe-log-groups --log-group-name-prefix "/thomas/webapp" --query 'logGroups[].logGroupName' --output text | head -5

health: ## Check application health
	@echo "🏥 Checking application health..."
	@URL=$$(terraform output -raw application_url 2>/dev/null); \
	if [ -n "$$URL" ]; then \
		curl -s -o /dev/null -w "Status: %{http_code}\nTime: %{time_total}s\n" $$URL/health.php || echo "❌ Health check failed"; \
	else \
		echo "❌ No application URL found. Infrastructure may not be deployed."; \
	fi

# Backup and restore
backup-state: ## Backup Terraform state
	@echo "💾 Backing up Terraform state..."
	@cp terraform.tfstate terraform.tfstate.backup.$(shell date +%Y%m%d_%H%M%S)
	@echo "✅ State backed up successfully!"

# Security
security-scan: ## Run security scan (requires tfsec)
	@echo "🔒 Running security scan..."
	@if command -v tfsec >/dev/null 2>&1; then \
		tfsec . --format json > security-report.json; \
		tfsec .; \
		echo "📄 Detailed report saved in security-report.json"; \
	else \
		echo "⚠️  tfsec not installed. Install with: brew install tfsec"; \
	fi

# Quick reference
quick-start: ## Show quick start guide
	@echo "🚀 Quick Start Guide"
	@echo "==================="
	@echo "1. make setup     - Setup development environment"
	@echo "2. make dev-deploy - Deploy infrastructure"
	@echo "3. make health    - Check application health"
	@echo "4. make dev-destroy - Clean up everything"
	@echo ""
	@echo "For production deployment:"
	@echo "1. Edit terraform.tfvars for production values"
	@echo "2. make prod-check"
	@echo "3. make init plan apply"
