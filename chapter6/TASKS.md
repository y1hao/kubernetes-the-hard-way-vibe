# Chapter 6 Execution Plan — Stable API Access

## Prerequisites
1. Confirm Chapter 1 Terraform state is up-to-date and accessible for VPC, subnet, and security group outputs.
2. Verify Chapter 2 Terraform state contains control plane instance IDs and private IPs required for target attachments.
3. Ensure Chapter 5 control plane services are healthy on `cp-a`, `cp-b`, and `cp-c` (`systemctl status kube-apiserver`).
4. Bastion host has AWS credentials and Terraform 1.13.3 configured for the new stack.

## Execution Steps
1. **Scaffold Terraform stack**
   - Create `chapter6/terraform/` with providers, backend (local state), and remote-state data sources for Chapters 1 & 2 outputs.
   - Define locals/variables for tagging, ports, health check settings, and DNS names.
2. **Provision NLB + target group**
   - Use Chapter 1 private subnet IDs to create an internal AWS NLB.
   - Create a TCP 6443 target group and register the three control plane instances (from Chapter 2 state) with cross-zone load balancing enabled.
   - Configure security group associations to allow NLB-to-control-plane traffic via existing rules.
3. **Add DNS records**
   - Create a private Route53 hosted zone for `kthw.lab` (if not already in AWS).
   - Publish an alias A record `api.kthw.lab` pointing to the new internal NLB.
4. **Terraform hygiene**
   - Run `terraform fmt`, `validate`, and `plan` with appropriate variables, ensuring there are no unintended changes.
   - Execute `terraform apply` once the plan is approved.
5. **Update kubeconfigs & documentation**
   - Confirm existing kubeconfigs already reference `api.kthw.lab`; adjust docs to note DNS is now authoritative.
   - Update `chapter6/README.md` with implementation notes and validation commands.
6. **Validation**
   - From the bastion, resolve `api.kthw.lab` and run `kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig get ns` to ensure traffic flows through the NLB.
   - Simulate failure by stopping kube-apiserver on one control plane node and confirm requests still succeed via the load balancer.
7. **Project docs**
   - After successful validation, append Chapter 6 summary to the top-level `README.md` per RULES.md.

## Validation Steps
1. `nslookup api.kthw.lab` (or `dig`) returns the NLB alias inside the VPC.
2. `kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig get --raw=/healthz` succeeds from the bastion using DNS.
3. NLB target group health checks report all three instances healthy; draining one node doesn’t break API access.
4. Terraform state in `chapter6/terraform/terraform.tfstate` reflects the new resources with no drift on re-run of `terraform plan`.
