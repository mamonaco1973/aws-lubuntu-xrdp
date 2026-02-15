# ==============================================================================
# Provider Configuration
# ------------------------------------------------------------------------------
# Defines the AWS provider and default region.
# Modify region if deploying outside us-east-1.
# ==============================================================================

provider "aws" {
  region = "us-east-1"
}


# ==============================================================================
# Data Source: AD Admin Secret
# ------------------------------------------------------------------------------
# Retrieves the AWS Secrets Manager secret containing AD admin credentials.
# Used for domain join and authentication operations.
# ==============================================================================

data "aws_secretsmanager_secret" "admin_secret" {
  name = "admin_ad_credentials_lubuntu"
}


# ==============================================================================
# Data Source: VPC (Active Directory)
# ------------------------------------------------------------------------------
# Locates the VPC used for Active Directory infrastructure.
# Filtered by Name tag provided via variable var.vpc_name.
# ==============================================================================

data "aws_vpc" "ad_vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}


# ==============================================================================
# Data Source: VM Subnet
# ------------------------------------------------------------------------------
# Retrieves subnet for EC2 desktop instances.
# Filtered by:
#   - VPC ID
#   - Name tag = vm-subnet-1
# ==============================================================================

data "aws_subnet" "vm_subnet_1" {

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.ad_vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["vm-subnet-1"]
  }
}


# ==============================================================================
# Data Source: AD Subnet
# ------------------------------------------------------------------------------
# Retrieves subnet used for Active Directory services.
# Filtered by:
#   - VPC ID
#   - Name tag = ad-subnet
# ==============================================================================

data "aws_subnet" "ad_subnet" {

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.ad_vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["ad-subnet"]
  }
}


# ==============================================================================
# Data Source: Windows Server 2022 AMI
# ------------------------------------------------------------------------------
# Retrieves the most recent Windows Server 2022 AMI from AWS.
# Ensures latest official base image is used for deployments.
# ==============================================================================

data "aws_ami" "windows_ami" {

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
}