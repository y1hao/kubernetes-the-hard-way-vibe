# Cleanup Checklist and Teardown Commands

Use this checklist to dismantle the Kubernetes the Hard Way lab. Commands are grouped so you can copy and run them from the repo root. Review state and plan outputs before executing destructive steps.

## Preconditions

- Confirm no workloads or data need to be preserved. This environment will be deleted permanently.
- Ensure your AWS credentials point to the same account/region used for provisioning.
- `terraform` version matches the pinned version used across chapters (1.13.3).

## Teardown Order

1. Destroy Chapter 13 public API exposure stack.
2. Destroy Chapter 10 app exposure stack.
3. Destroy Chapter 6 internal API access stack.
4. Destroy Chapter 2 node provisioning stack (instances).
5. Destroy Chapter 1 network substrate stack (VPC).

## Copy-Pasteable Commands

```bash
# Navigate to repo root
cd "$(git rev-parse --show-toplevel)"

# Capture current public IP for stacks that require admin CIDR input
ADMIN_IP=$(curl -fsS ifconfig.me)
ADMIN_CIDR="${ADMIN_IP}/32"

# Chapter 13: Public API exposure
bin/terraform -chdir=chapter13/terraform destroy \
  -var="admin_cidr_blocks=[\"${ADMIN_CIDR}\"]"

# Chapter 10: App exposure
bin/terraform -chdir=chapter10/terraform destroy

# Chapter 6: Internal API access
bin/terraform -chdir=chapter6/terraform destroy

# Chapter 2: Nodes (control planes + workers)
bin/terraform -chdir=chapter2/terraform destroy

# Chapter 1: Network substrate
bin/terraform -chdir=chapter1/terraform destroy \
  -var="admin_cidr_blocks=[\"${ADMIN_CIDR}\"]"
```

Each `terraform destroy` run will present the plan and prompt for confirmation; answer `yes` when you are satisfied. If Terraform complains about missing plugins or state, run `terraform init` in that directory once and retry the destroy.

> **Note**: If a plan step reveals resources you intend to keep temporarily (e.g., bastion for postmortem), cancel and update the stack manually before re-running.

## Manual Resource Checklist

- [ ] Confirm no EC2 instances remain with tags `Project=K8sHardWay`.

  ```bash
  aws ec2 describe-instances \
    --filters "Name=tag:Project,Values=K8sHardWay" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --query 'Reservations[].Instances[].[InstanceId,State.Name,Tags]' \
    --output table
  ```

- [ ] Check for unattached EBS volumes created by the cluster.

  ```bash
  aws ec2 describe-volumes \
    --filters "Name=tag:Project,Values=K8sHardWay" "Name=status,Values=available" \
    --query 'Volumes[].[VolumeId,State,Tags]' \
    --output table
  ```

- [ ] Verify Network Load Balancers (internal and public) are deleted.

  ```bash
  aws elbv2 describe-load-balancers \
    --query 'LoadBalancers[?contains(LoadBalancerName, `kthw`)].[LoadBalancerName,DNSName,State.Code,Type]' \
    --output table
  ```

- [ ] Ensure Route53 records created for the cluster are removed.

  ```bash
  HOSTED_ZONE_ID="<your_private_zone_or_public_zone_id>"
  aws route53 list-resource-record-sets \
    --hosted-zone-id "${HOSTED_ZONE_ID}" \
    --query 'ResourceRecordSets[?contains(Name, `kthw`)]'
  ```

- [ ] Confirm VPC, subnets, route tables, and security groups tagged for the project are gone.

  ```bash
  aws ec2 describe-vpcs \
    --filters "Name=tag:Project,Values=K8sHardWay" \
    --query 'Vpcs[].[VpcId,State,Tags]' \
    --output table

  aws ec2 describe-subnets \
    --filters "Name=tag:Project,Values=K8sHardWay" \
    --query 'Subnets[].[SubnetId,AvailabilityZone,CidrBlock,Tags]' \
    --output table

  aws ec2 describe-route-tables \
    --filters "Name=tag:Project,Values=K8sHardWay" \
    --query 'RouteTables[].[RouteTableId,Tags]' \
    --output table

  aws ec2 describe-security-groups \
    --filters "Name=tag:Project,Values=K8sHardWay" \
    --query 'SecurityGroups[].[GroupId,GroupName,VpcId,Tags]' \
    --output table
  ```

- [ ] Remove IAM roles, instance profiles, and key pairs created for the environment if not reused.

  ```bash
  aws iam list-roles \
    --query 'Roles[?contains(RoleName, `kthw`) == `true`].RoleName' \
    --output text
  for role in $(aws iam list-roles --query 'Roles[?contains(RoleName, `kthw`) == `true`].RoleName' --output text); do
    aws iam list-role-tags --role-name "$role"
  done

  aws iam list-instance-profiles \
    --query 'InstanceProfiles[?contains(InstanceProfileName, `kthw`) == `true`].[InstanceProfileName,Roles]' \
    --output table

  aws ec2 describe-key-pairs \
    --filters "Name=tag:Project,Values=K8sHardWay" \
    --query 'KeyPairs[].[KeyName,KeyPairId,Tags]' \
    --output table
  ```

- [ ] Delete any S3 buckets or objects that stored Terraform state (if this lab used a dedicated bucket).

  ```bash
  aws s3 ls | grep kthw || true
  # If a dedicated bucket exists, empty it before deletion, e.g.:
  aws s3 rm s3://<kthw-terraform-state-bucket>/ --recursive
  aws s3api delete-bucket --bucket <kthw-terraform-state-bucket>
  ```

- [ ] Confirm local artifacts (kubeconfigs, certs) are archived or deleted per your security requirements.

  ```bash
  find chapter3/pki -maxdepth 2 -type f -print
  find chapter3/encryption -type f -print
  find chapter13/kubeconfigs -type f -print
  # Archive or securely delete as appropriate.
  ```

## Post Teardown

- Optionally re-run `terraform state list` in each chapter to ensure no resources remain tracked.
- Update `README.md` and documentation with the final teardown date if required.
