#!/bin/bash
# ==============================================================================
# AD + Server Infrastructure Teardown Script
# ------------------------------------------------------------------------------
# Performs controlled teardown of deployed AWS resources:
#   1. Destroy EC2 servers (Terraform).
#   2. Deregister Packer-built AMIs and delete snapshots.
#   3. Delete AD secrets and destroy AD infrastructure.
#
# WARNING:
#   - Secrets are deleted with no recovery window.
#   - Requires AWS CLI and Terraform configured.
#   - Intended for full environment removal.
#
# Exit Codes:
#   - 0 : Success.
#   - 1 : Missing dirs or Terraform/AWS CLI failure.
# ==============================================================================

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
export AWS_DEFAULT_REGION="us-east-1"
set -e


# ------------------------------------------------------------------------------
# Phase 1: Destroy EC2 Server Instances
# ------------------------------------------------------------------------------
# Removes all resources defined in 03-servers Terraform module.
# ------------------------------------------------------------------------------
echo "NOTE: Destroying EC2 server instances..."

cd 03-servers || { echo "ERROR: Missing 03-servers dir"; exit 1; }

terraform init
terraform destroy -auto-approve

cd .. || exit


# ------------------------------------------------------------------------------
# Phase 2: Deregister AMIs and Delete Snapshots
# ------------------------------------------------------------------------------
# Removes AMIs matching lubuntu_ami* pattern and deletes snapshots.
# ------------------------------------------------------------------------------
echo "NOTE: Deregistering project AMIs and deleting snapshots..."

for ami_id in $(aws ec2 describe-images \
    --owners self \
    --filters "Name=name,Values=lubuntu_ami*" \
    --query "Images[].ImageId" \
    --output text); do

  for snapshot_id in $(aws ec2 describe-images \
      --image-ids "$ami_id" \
      --query "Images[].BlockDeviceMappings[].Ebs.SnapshotId" \
      --output text); do

    echo "NOTE: Deregistering AMI: $ami_id"
    aws ec2 deregister-image --image-id "$ami_id"

    echo "NOTE: Deleting snapshot: $snapshot_id"
    aws ec2 delete-snapshot --snapshot-id "$snapshot_id"

  done
done


# ------------------------------------------------------------------------------
# Phase 3: Destroy AD Resources
# ------------------------------------------------------------------------------
# Permanently delete AD Secrets Manager entries and destroy AD module.
# ------------------------------------------------------------------------------
echo "NOTE: Deleting AD secrets..."

aws secretsmanager delete-secret \
  --secret-id "akumar_ad_credentials_lubuntu" \
  --force-delete-without-recovery

aws secretsmanager delete-secret \
  --secret-id "jsmith_ad_credentials_lubuntu" \
  --force-delete-without-recovery

aws secretsmanager delete-secret \
  --secret-id "edavis_ad_credentials_lubuntu" \
  --force-delete-without-recovery

aws secretsmanager delete-secret \
  --secret-id "rpatel_ad_credentials_lubuntu" \
  --force-delete-without-recovery

aws secretsmanager delete-secret \
  --secret-id "admin_ad_credentials_lubuntu" \
  --force-delete-without-recovery


echo "NOTE: Destroying AD Terraform resources..."

cd 01-directory || { echo "ERROR: Missing 01-directory dir"; exit 1; }

terraform init
terraform destroy -auto-approve

cd .. || exit


# ------------------------------------------------------------------------------
# Completion
# ------------------------------------------------------------------------------
echo "NOTE: Infrastructure teardown complete."

# ==============================================================================
# End of Script
# ==============================================================================