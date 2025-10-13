# Chapter 1 Execution Plan — AWS Network Substrate

## Execution Steps
1. **Tooling prep**: Ensure Terraform `1.13.3`, AWS CLI v2, and `jq` 1.6 are installed locally; configure AWS credentials/profile targeting `ap-southeast-2`.
2. **SSH material**: Generate the `ed25519` key pair (`kthw-lab`) and register its public key as an AWS key pair for use by bastion and node instances.
3. **Terraform scaffold**: Create the Chapter 1 Terraform structure (`providers.tf`, `variables.tf`, `outputs.tf`, and module directories) capturing region, AZ ZoneIds, CIDRs, and tagging conventions.
4. **VPC & routing**: Implement VPC, Internet Gateway, main route table associations, and outputs exposing identifiers needed by later chapters.
5. **Subnet layout**: Add three public and three private subnets aligned to the AZ mapping, with deterministic CIDR assignments and tags.
6. **NAT gateway**: Provision an Elastic IP, managed NAT gateway in the chosen public subnet, and private route tables pointing default routes to the NAT.
7. **Security groups**: Define bastion/NLB ingress security groups and a baseline node security group with the minimal required rules for etcd, API server, SSH, and NodePort placeholders.
8. **Variables & docs**: Populate `chapter1/inputs.md` summarising constants; embed defaults/comments in Terraform variables for reuse.
9. **Outputs & locals**: Expose subnet IDs, security group IDs, and key network artifacts through Terraform outputs for downstream modules.
10. **Documentation**: Record security group rule matrices, NAT cost notes, and apply/destroy instructions in Chapter 1 notes.

## Validation Steps
1. Run `terraform fmt`, `terraform validate`, and a targeted `terraform plan` to confirm configuration correctness before applying.
2. After `terraform apply`, verify via AWS CLI describes that subnets, route tables, and NAT gateway are attached to the intended AZs and CIDRs.
3. From the bastion (once provisioned), confirm outbound internet access through the NAT and private subnet reachability to planned node IP ranges.
4. Update project logs with Terraform outputs and link back to ADR `000` for traceability.
