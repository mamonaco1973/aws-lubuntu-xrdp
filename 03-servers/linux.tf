# ==============================================================================
# Data Source: Latest Lubuntu AMI
# ------------------------------------------------------------------------------
# Retrieves the most recent Lubuntu AMI built via Packer.
# Filters:
#   - Name starts with "lubuntu_ami"
#   - AMI state is "available"
#   - Owned by this AWS account
# ==============================================================================

data "aws_ami" "latest_desktop_ami" {

  most_recent = true

  # Filter by AMI name prefix.
  filter {
    name   = "name"
    values = ["lubuntu_ami*"]
  }

  # Ensure AMI is available.
  filter {
    name   = "state"
    values = ["available"]
  }

  # Limit to AMIs owned by this account.
  owners = ["self"]
}


# ==============================================================================
# EC2 Instance: Lubuntu Desktop
# ------------------------------------------------------------------------------
# Provisions an Ubuntu 24.04 desktop instance.
# Integrates with Active Directory and mounts Amazon EFS.
# ==============================================================================

resource "aws_instance" "lubuntu_instance" {

  # ---------------------------------------------------------------------------
  # Amazon Machine Image (AMI)
  # ---------------------------------------------------------------------------
  # Dynamically resolved to latest Lubuntu AMI.
  ami = data.aws_ami.latest_desktop_ami.id


  # ---------------------------------------------------------------------------
  # Instance Type
  # ---------------------------------------------------------------------------
  # Desktop workload instance size.
  instance_type = "m5.xlarge"


  # ---------------------------------------------------------------------------
  # Root Block Device
  # ---------------------------------------------------------------------------
  # gp3 SSD root volume, 64 GiB.
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 64
    delete_on_termination = true
  }


  # ---------------------------------------------------------------------------
  # Networking
  # ---------------------------------------------------------------------------
  # Subnet placement and security groups.
  subnet_id = data.aws_subnet.vm_subnet_1.id

  vpc_security_group_ids = [
    aws_security_group.ad_ssh_sg.id,
    aws_security_group.ad_rdp_sg.id
  ]

  # Assign public IP at launch.
  associate_public_ip_address = true


  # ---------------------------------------------------------------------------
  # IAM Instance Profile
  # ---------------------------------------------------------------------------
  # Grants access to AWS services (Secrets Manager, SSM, etc).
  iam_instance_profile = aws_iam_instance_profile.ec2_secrets_profile.name


  # ---------------------------------------------------------------------------
  # User Data Bootstrap
  # ---------------------------------------------------------------------------
  # Passes environment values into userdata.sh template.
  user_data = templatefile("./scripts/userdata.sh", {
    admin_secret   = "admin_ad_credentials_lubuntu"
    domain_fqdn    = var.dns_zone
    efs_mnt_server = aws_efs_mount_target.efs_mnt_1.dns_name
    netbios        = var.netbios
    realm          = var.realm
    force_group    = "mcloud-users"
  })


  # ---------------------------------------------------------------------------
  # Tags
  # ---------------------------------------------------------------------------
  tags = {
    Name = "lubuntu-instance"
  }


  # ---------------------------------------------------------------------------
  # Dependencies
  # ---------------------------------------------------------------------------
  # Ensure EFS and mount targets exist before launch.
  depends_on = [
    aws_efs_file_system.efs,
    aws_efs_mount_target.efs_mnt_1,
    aws_efs_mount_target.efs_mnt_2
  ]
}