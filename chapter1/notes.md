# Chapter 1 Notes — AWS Network Substrate

## Terraform Usage
- Format & validate: `bin/terraform -chdir=chapter1/terraform fmt` and `bin/terraform -chdir=chapter1/terraform validate`.
- Preview changes with current operator IP (used only for bastion ingress): `IP=$(curl -fsS ifconfig.me)` and `bin/terraform -chdir=chapter1/terraform plan -var "admin_cidr_blocks=[\"${IP}/32\"]"`.
- Apply with current operator IP: `IP=$(curl -fsS ifconfig.me)` and `bin/terraform -chdir=chapter1/terraform apply -var "admin_cidr_blocks=[\"${IP}/32\"]"`.
- Destroy (when finished): reuse the latest IP with `bin/terraform -chdir=chapter1/terraform destroy -var "admin_cidr_blocks=[\"${IP}/32\"]"`.

### When Your IP Changes Later
1. Re-evaluate your public IP: `NEW_IP=$(curl -fsS ifconfig.me)`.
2. Re-run `terraform plan` or `apply` with `-var "admin_cidr_blocks=[\"${NEW_IP}/32\"]"` to refresh the bastion ingress rule.
3. If Terraform state already exists, a fresh `apply` updates the bastion security group without recreating infrastructure.

## Security Group Matrix (Ingress)
| Security Group | Purpose | Source | Ports | Notes |
| --- | --- | --- | --- | --- |
| `kthw-bastion` | SSH bastion | Admin CIDR list | 22/tcp | Outbound open for package retrieval |
| `kthw-control-plane` | Control plane nodes | Bastion SG | 22/tcp | Admin SSH |
|  |  | Worker SG | 6443/tcp | kube-apiserver from workers |
|  |  | Bastion SG | 6443/tcp | kubectl via bastion |
|  |  | Self | 2379-2380/tcp | etcd peer/client |
| `kthw-worker` | Worker nodes | Bastion SG | 22/tcp | Admin SSH |
|  |  | Control plane SG | 10250/tcp | kubelet API from control plane |
|  |  | NodePort CIDR list | 30000-32767/tcp | Optional app exposure |
| `kthw-api-nlb` | API Network LB | Bastion SG | 6443/tcp | Fronts kube-apiserver via bastion |

## Bastion Host Notes
- Instance: Ubuntu 22.04 LTS (`t3.micro`) in public subnet suffix `a` with static private IP `10.240.0.10` and an auto-assigned public IP.
- SSH: `ssh -i chapter1/kthw-lab ubuntu@$(bin/terraform -chdir=chapter1/terraform output -raw bastion_public_ip)`.
- Environment prep (optional): install `awscli`, `jq`, `kubectl`, `cfssl`, and `terraform` as needed to operate from the bastion.

## NAT Gateway Notes
- Hosted in public subnet suffix `a`; ensure that subnet spans the AZ used by the bastion for minimized latency.
- Managed NAT incurs hourly + data processing charges; consider destroying if the lab is idle.

## Outputs to Record
- VPC ID, subnet ID maps, NAT gateway ID, security group IDs (exported via `terraform output --json`).
- Track values in Chapter 1 summary for quick reuse in Chapter 2 provisioning scripts.

## Follow-up
- Supply actual admin CIDR(s) and optional NodePort sources when applying Terraform.
- After EC2 provisioning, confirm outbound internet from private subnets via bastion (curl to public endpoints).
