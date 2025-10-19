# Chapter 13 Terraform Stack

## Variables
- `aws_region` — Region to operate in (defaults to `ap-southeast-2`, override if your lab differs).
- `admin_cidr_blocks` — **Required.** List of CIDR ranges allowed to reach the public kube-apiserver on TCP 6443.
- `enable_cross_zone` — Toggle for cross-zone load balancing on the public NLB (defaults to `true`).
- `extra_tags` — Optional map of tags merged into every resource.

## Outputs
- `public_api_nlb_dns_name` — AWS-provided hostname operators use in kubeconfigs.
- `public_api_nlb_arn` — ARN for auditing or tagging workflows.
- `public_api_target_group_arn` — Target group identifier for health checks.
- `public_api_security_group_id` — Security group controlling admin CIDR ingress.

## Usage
Fetch remote state from Chapters 1 and 2 and run Terraform commands via the project wrapper:
```
bin/terraform -chdir=chapter13/terraform init
bin/terraform -chdir=chapter13/terraform fmt
bin/terraform -chdir=chapter13/terraform validate
bin/terraform -chdir=chapter13/terraform plan \
  -var='admin_cidr_blocks=["203.0.113.0/24"]'
```
