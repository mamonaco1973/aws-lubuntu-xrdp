# ==============================================================================
# EC2 Instance: Windows AD Administration Server
# ------------------------------------------------------------------------------
# Deploys a Windows Server instance used for AD administration.
#
# Notes:
#   - NOT a Domain Controller.
#   - Used for RDP access and AD management tools (RSAT, ADUC, PowerShell).
#   - Connects to AD services hosted on separate infrastructure.
# ==============================================================================

resource "aws_instance" "windows_ad_instance" {

  # ---------------------------------------------------------------------------
  # Amazon Machine Image (AMI)
  # ---------------------------------------------------------------------------
  # Uses latest Windows Server 2022 AMI from data source.
  ami = data.aws_ami.windows_ami.id


  # ---------------------------------------------------------------------------
  # Instance Type
  # ---------------------------------------------------------------------------
  # t3.medium: 2 vCPU, 4 GiB RAM.
  # Suitable for AD tools and RDP administration.
  instance_type = "t3.medium"


  # ---------------------------------------------------------------------------
  # Networking
  # ---------------------------------------------------------------------------
  # Launch into designated subnet.
  subnet_id = data.aws_subnet.vm_subnet_1.id

  # Apply security groups.
  vpc_security_group_ids = [
    aws_security_group.ad_rdp_sg.id
  ]

  # Assign public IP at launch.
  # Restrict RDP access to trusted IP ranges.
  associate_public_ip_address = true


  # ---------------------------------------------------------------------------
  # IAM Instance Profile
  # ---------------------------------------------------------------------------
  # Grants access to AWS services (Secrets Manager, SSM).
  iam_instance_profile = aws_iam_instance_profile.ec2_secrets_profile.name


  # ---------------------------------------------------------------------------
  # User Data Bootstrap
  # ---------------------------------------------------------------------------
  # Executes PowerShell script on first boot.
  # Parameters:
  #   - admin_secret : Secrets Manager entry for admin credentials.
  #   - domain_fqdn  : AD domain FQDN.
  #   - samba_server : Private DNS of Lubuntu instance.
  user_data = templatefile("./scripts/userdata.ps1", {
    admin_secret = "admin_ad_credentials_lubuntu"
    domain_fqdn  = var.dns_zone
    samba_server = aws_instance.lubuntu_instance.private_dns
  })


  # ---------------------------------------------------------------------------
  # Tags
  # ---------------------------------------------------------------------------
  tags = {
    Name = "lubuntu-ad-admin"
  }


  # ---------------------------------------------------------------------------
  # Dependencies
  # ---------------------------------------------------------------------------
  # Ensure Xubuntu instance exists before admin server launch.
  depends_on = [
    aws_instance.lubuntu_instance
  ]
}