# Chapter 2 Execution Plan — EC2 Node Provisioning

## Prerequisites
1. **AWS credentials**: Same profile used in Chapter 1 with permissions for EC2, IAM (key pair lookup), and SSM parameter reads.
2. **Terraform tooling**: Reuse `bin/terraform` (v1.13.3) and keep Chapter 1 state (`chapter1/terraform/terraform.tfstate`) intact for remote-state lookups.
3. **SSH material**: Confirm the `kthw-lab` key pair exists locally and in AWS; no new key creation required.

## Execution Steps
1. **Terraform scaffold**
   - Create `chapter2/terraform/` with provider configuration, variables, outputs, and locals.
   - Define `data "terraform_remote_state"` reading `../chapter1/terraform/terraform.tfstate` to import VPC IDs, subnet IDs, and security groups.
2. **Instance module**
   - Implement resources for five `aws_instance` objects (3 control planes, 2 workers) using the static private IP map from ADR 002.
   - Pull the Ubuntu 22.04 AMI via `data "aws_ssm_parameter"` and `data "aws_ami"` lookup; allow per-role instance types.
   - Attach the existing security groups, private subnets, `kthw` tags, and `kthw-lab` SSH key.
   - Configure 20 GiB gp3 root volumes and per-instance name/hostname tags.
3. **Cloud-init templates**
   - Author `chapter2/cloud-init/control-plane.yaml` and `chapter2/cloud-init/worker.yaml` implementing the base OS prep: swap off, module loads, sysctls, package updates, core tooling install.
   - Wire the templates into Terraform using `templatefile` and `user_data` for the respective node sets.
4. **Outputs & inventory generation**
   - Add Terraform outputs for instance IDs, private IPs, AZ suffix mapping, and bastion connection hints.
   - Create `chapter2/inventory.yaml` reflecting logical names, AZs, private IPs, and roles; include bastion host placeholder to fill after Chapter 1 apply.
5. **Validation scripting**
   - Implement `chapter2/scripts/validate_nodes.sh` to run from the bastion, iterating over `inventory.yaml` to confirm:
     - SSH reachability (`ssh -J bastion node`)
     - Swap disabled (`swapon --show` empty)
     - Required kernel modules loaded (`overlay`, `br_netfilter`)
     - Sysctls set (`net.bridge.bridge-nf-call-iptables=1`, etc.)
   - Document usage (environment variables, paths) at the top of the script.
6. **Documentation updates**
   - Extend `SPEC.md` Chapter 2 section with concrete instance specs, IP map, and references to automation artifacts.
   - Update `README.md` Chapter summaries and add Chapter 2 “How to run” notes.
   - Add Chapter 2 notes file capturing Terraform apply/destroy commands and validation instructions.

## Validation Steps
1. Run `bin/terraform -chdir=chapter2/terraform fmt`, `validate`, and `plan` to catch configuration errors before applying.
2. After `terraform apply`, export outputs to JSON and ensure IPs match the planned map; record values in Chapter 2 notes.
3. From the bastion, execute `chapter2/scripts/validate_nodes.sh` and confirm all checks pass.
4. Capture validation results and any deviations in `chapter2/notes.md` (to be created alongside documentation updates).
