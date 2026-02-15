# ==============================================================================
# Packer Build: Lubuntu AMI on Ubuntu 24.04 (Noble)
# ------------------------------------------------------------------------------
# Builds a custom Lubuntu XRDP AMI for AWS.
# Base image: Canonical Ubuntu 24.04 (Noble).
# Output: Timestamped AMI for Terraform or EC2 launches.
# ==============================================================================


# ------------------------------------------------------------------------------
# Packer Plugin Configuration
# ------------------------------------------------------------------------------
# Defines required Amazon plugin for AWS builds.
# ------------------------------------------------------------------------------
packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}


# ------------------------------------------------------------------------------
# Data Source: Base Ubuntu 24.04 AMI
# ------------------------------------------------------------------------------
# Retrieves latest Canonical-owned Ubuntu Noble AMI.
# ------------------------------------------------------------------------------
data "amazon-ami" "ubuntu_2404" {
  filters = {
    name  = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
    virtualization-type = "hvm"
    root-device-type    = "ebs"
  }

  most_recent = true
  owners      = ["099720109477"]
}


# ------------------------------------------------------------------------------
# Variables: Build Inputs
# ------------------------------------------------------------------------------
# Control region, instance type, and network placement.
# ------------------------------------------------------------------------------
variable "region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "m5.2xlarge"
}

variable "vpc_id" {
  description = "VPC ID for build instance."
  default     = ""
}

variable "subnet_id" {
  description = "Subnet ID for build instance."
  default     = ""
}


# ------------------------------------------------------------------------------
# Amazon EBS Source
# ------------------------------------------------------------------------------
# Launches temporary EC2 instance and produces reusable AMI.
# ------------------------------------------------------------------------------
source "amazon-ebs" "lubuntu_ami" {

  region        = var.region
  instance_type = var.instance_type
  source_ami    = data.amazon-ami.ubuntu_2404.id
  ssh_username  = "ubuntu"

  ami_name =
    "lubuntu_ami_${replace(timestamp(), ":", "-")}"

  ssh_interface = "public_ip"
  vpc_id        = var.vpc_id
  subnet_id     = var.subnet_id

  # ---------------------------------------------------------------------------
  # Root Volume
  # ---------------------------------------------------------------------------
  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = "64"
    volume_type           = "gp3"
    delete_on_termination = "true"
  }

  tags = {
    Name = "lubuntu_ami_${replace(timestamp(), ":", "-")}"
  }
}


# ------------------------------------------------------------------------------
# Build Block
# ------------------------------------------------------------------------------
# Executes provisioning scripts inside temporary instance.
# ------------------------------------------------------------------------------
build {
  sources = ["source.amazon-ebs.lubuntu_ami"]

  # Install base packages.
  provisioner "shell" {
    script          = "./packages.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install Lubuntu desktop.
  provisioner "shell" {
    script          = "./lubuntu.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install XRDP.
  provisioner "shell" {
    script          = "./xrdp.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install Google Chrome.
  provisioner "shell" {
    script          = "./chrome.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install Firefox.
  provisioner "shell" {
    script          = "./firefox.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install VS Code.
  provisioner "shell" {
    script          = "./vscode.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install HashiCorp tools.
  provisioner "shell" {
    script          = "./hashicorp.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install AWS CLI.
  provisioner "shell" {
    script          = "./awscli.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install Azure CLI.
  provisioner "shell" {
    script          = "./azcli.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install Google Cloud CLI.
  provisioner "shell" {
    script          = "./gcloudcli.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install Docker.
  provisioner "shell" {
    script          = "./docker.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install Postman.
  provisioner "shell" {
    script          = "./postman.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install KRDC.
  provisioner "shell" {
    script          = "./krdc.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install OnlyOffice.
  provisioner "shell" {
    script          = "./onlyoffice.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Configure desktop icons.
  provisioner "shell" {
    script          = "./desktop.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }
}
