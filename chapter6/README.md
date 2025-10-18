# Chapter 6 — Stable API Access

## Overview
Chapter 6 introduces an internal AWS Network Load Balancer and Route53 private DNS so every client can reach the Kubernetes API through the shared `api.kthw.lab` endpoint. The stack consumes Chapter 1 networking outputs and Chapter 2 instance metadata, aligning with ADR 006 decisions.

## Terraform Usage
```
cd ~/kubernetes-the-hard-way-vibe
bin/terraform -chdir=chapter6/terraform init
bin/terraform -chdir=chapter6/terraform fmt
bin/terraform -chdir=chapter6/terraform validate
bin/terraform -chdir=chapter6/terraform plan
bin/terraform -chdir=chapter6/terraform apply
bin/terraform -chdir=chapter6/terraform output
```

Key outputs after apply:
- `api_nlb_dns_name` — internal hostname of the NLB
- `api_nlb_arn` — resource ARN for auditing or tagging tweaks
- `api_target_group_arn` — target group ARN for health checks/automation

## Work Completed
- Created `chapter6/terraform/` with remote-state references to Chapters 1 & 2.
- Provisioned an internal NLB (`kthw-api-nlb`) spanning the three private subnets with TCP 6443 listener and target group.
- Attached `cp-a`, `cp-b`, and `cp-c` instances to the target group for load-balanced API access.
- Added a private Route53 hosted zone `kthw.lab` and an alias A record `api.kthw.lab` pointing at the NLB.
- Left the control-plane `/etc/hosts` shim intact while documenting DNS as the canonical endpoint for clients.

## Validation
Run these from the bastion once DNS propagates:
```
nslookup api.kthw.lab
kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig get ns
kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig get --raw=/healthz
```
Expected results:
- DNS resolves `api.kthw.lab` to the NLB alias.
- `kubectl` calls succeed through the load balancer.
- AWS console or `aws elbv2 describe-target-health --target-group-arn $(bin/terraform -chdir=chapter6/terraform output -raw api_target_group_arn)` reports all three targets healthy; stopping kube-apiserver on one node should not break access.

## Notes
- The Route53 zone is private to the VPC; ensure clients run within the VPC or use conditional forwarding.
- Retaining the `/etc/hosts` entry on control planes preserves local resiliency but bypasses the NLB for on-host operations.
- Future chapters should reuse the shared endpoint (`https://api.kthw.lab:6443`) when generating kubeconfigs or automation.
