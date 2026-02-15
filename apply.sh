#!/bin/bash
# ==============================================================================
# AD + Server Deployment Orchestration Script
# ------------------------------------------------------------------------------
# Automates a three-phase build:
#   1. Deploy Active Directory resources with Terraform.
#   2. Build a Lubuntu XRDP AMI with Packer.
#   3. Deploy EC2 servers and join them to the AD domain.
#
# Requirements:
#   - AWS CLI configured.
#   - Terraform and Packer installed.
#   - ./check_env.sh available for pre-check validation.
#   - ./validate.sh available for post-build verification.
#
# Exit Codes:
#   - 0 : Success.
#   - 1 : Failed pre-check or missing directories.
# ==============================================================================

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
export AWS_DEFAULT_REGION="us-east-1"
DNS_ZONE="mcloud.mikecloud.com"
set -e


# ------------------------------------------------------------------------------
# Environment Pre-Check
# ------------------------------------------------------------------------------
# Validate tooling and local prerequisites before starting.
# ------------------------------------------------------------------------------
echo "NOTE: Running environment validation..."
./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi


# ------------------------------------------------------------------------------
# Phase 1: Build AD Instance
# ------------------------------------------------------------------------------
# Deploy AD first to ensure DNS and domain join prerequisites exist.
# ------------------------------------------------------------------------------
echo "NOTE: Building Active Directory instance..."

cd 01-directory || { echo "ERROR: Missing 01-directory dir"; exit 1; }

terraform init
terraform apply -auto-approve

cd .. || exit


# ------------------------------------------------------------------------------
# Phase 2: Build Lubuntu XRDP AMI with Packer
# ------------------------------------------------------------------------------
# Resolve network values from the target VPC/subnet, then build the AMI.
# ------------------------------------------------------------------------------
vpc_id=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=lubuntu-vpc" \
  --query "Vpcs[0].VpcId" \
  --output text)

subnet_id=$(aws ec2 describe-subnets \
  --filters \
    "Name=vpc-id,Values=${vpc_id}" \
    "Name=tag:Name,Values=vm-subnet-1" \
  --query "Subnets[0].SubnetId" \
  --output text)

cd 02-packer || { echo "ERROR: Missing 02-packer dir"; exit 1; }

echo "NOTE: Building Lubuntu XRDP AMI with Packer..."

packer init ./lubuntu_ami.pkr.hcl
packer build -var "vpc_id=${vpc_id}" -var "subnet_id=${subnet_id}" \
  ./lubuntu_ami.pkr.hcl || {
    echo "ERROR: Packer build failed. Aborting."
    cd ..
    exit 1
  }

cd .. || exit


# ------------------------------------------------------------------------------
# Phase 3: Build EC2 Server Instances
# ------------------------------------------------------------------------------
# Deploy servers after AMI build completes.
# ------------------------------------------------------------------------------
echo "NOTE: Building EC2 server instances..."

cd 03-servers || { echo "ERROR: Missing 03-servers dir"; exit 1; }

terraform init
terraform apply -auto-approve

cd .. || exit


# ------------------------------------------------------------------------------
# Build Validation
# ------------------------------------------------------------------------------
# Run post-build validation checks.
# ------------------------------------------------------------------------------
./validate.sh