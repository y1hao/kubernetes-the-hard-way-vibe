# ADR: Chapter 2 Node Provisioning Decisions

## Status
Accepted

## Context
With Chapter 1 complete, the network substrate (VPC, subnets, security groups, NAT) is in place. Chapter 2 focuses on bringing up the six EC2 nodes (three control planes and three workers) that will host the Kubernetes control plane, etcd, and workloads in later chapters. We needed to lock in instance characteristics, address assignments, bootstrapping tooling, and Terraform layout so implementation can proceed without open design questions.

## Decision
- **Instance class & count**: Provision six `t3.medium` instances (2 vCPU, 4 GiB RAM) evenly spread across the three availability zones selected in ADR 000. This keeps costs low (~USD $110 for a two-week lab run) while providing enough capacity for etcd, control plane components, and lightweight demos.
- **AMI sourcing**: Pull the latest Ubuntu 22.04 LTS AMI dynamically via the public SSM parameter `/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp3`. This avoids hard-coding AMI IDs and keeps images patched.
- **Root volume sizing**: Override the default root disk to 20 GiB gp3 on every node to prevent log or package exhaustion during multi-chapter bring-up.
- **Static addressing**: Pin deterministic private IPs per node within their AZ subnets: `cp-a 10.240.16.10`, `worker-a 10.240.16.20`, `cp-b 10.240.48.10`, `worker-b 10.240.48.20`, `cp-c 10.240.80.10`, `worker-c 10.240.80.20`. This aligns with hostname suffixes and simplifies certificate SANs later.
- **Cloud-init strategy**: Use role-specific cloud-init templates (one for control planes, one for workers) to apply base OS preparation at first boot: disable swap, load `overlay` and `br_netfilter`, apply Kubernetes-required sysctls, perform `apt-get update && dist-upgrade`, install core tooling (`chrony`, `conntrack`, `socat`, `iptables`, `nfs-common`, `curl`, `jq`), and drop helper scripts. Installation of container runtimes and Kubernetes binaries remains out of scope until Chapters 5 and 7.
- **Terraform layout**: Create a dedicated root module under `chapter2/terraform` that consumes Chapter 1 outputs via `terraform_remote_state` pointing to the local `../chapter1/terraform/terraform.tfstate`. This keeps node lifecycle separate from the network while reusing established IDs and tags.
- **Inventory & validation artifacts**: Emit a checked-in YAML inventory (`chapter2/inventory.yaml`) mapping logical node names to IPs, AZs, and roles, plus a shell-based validation script (`chapter2/scripts/validate_nodes.sh`) runnable from the bastion to confirm SSH reachability, swap status, kernel modules, and sysctl values.

## Consequences
- Cloud-init keeps node preparation reproducible without introducing an additional configuration management tool, while separate templates leave room for future role divergence.
- Static IP assignments ensure the PKI work in Chapter 3 can pre-compute SANs confidently and that documentation matches reality.
- Depending on Chapter 1 local Terraform state means state files must remain accessible before Chapter 2 runs; migrating to a remote backend later would require updating the data source.
- Larger root volumes slightly increase EBS costs (~USD $3 for two weeks) but avoid rebuilds later due to disk exhaustion.

## Follow-up
- Author the control-plane and worker cloud-init templates under `chapter2/cloud-init/` during implementation.
- Scaffold the Terraform module with variables for static IP map, AMI lookup, root volume size, and SSH key association.
- Generate the inventory and validation script once Terraform outputs are available.
- Update future chapters (PKI, control plane, workers) to reference the agreed IP and hostname mappings.
