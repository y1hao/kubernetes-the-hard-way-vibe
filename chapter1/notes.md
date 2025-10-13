# Chapter 1 Notes — AWS Network Substrate

## Terraform Usage
- Format & validate: `bin/terraform -chdir=chapter1/terraform fmt` and `bin/terraform -chdir=chapter1/terraform validate`.
- Preview changes: `bin/terraform -chdir=chapter1/terraform plan -var 'admin_cidr_blocks=["<your-ip>/32"]'`.
- Apply: `bin/terraform -chdir=chapter1/terraform apply -var 'admin_cidr_blocks=["<your-ip>/32"]'`.
- Destroy (when finished): `bin/terraform -chdir=chapter1/terraform destroy -var 'admin_cidr_blocks=["<your-ip>/32"]'`.

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
| `kthw-api-nlb` | API Network LB | Admin CIDR list | 6443/tcp | Fronts kube-apiserver |

## NAT Gateway Notes
- Hosted in public subnet suffix `a`; ensure that subnet spans the AZ used by the bastion for minimized latency.
- Managed NAT incurs hourly + data processing charges; consider destroying if the lab is idle.

## Outputs to Record
- VPC ID, subnet ID maps, NAT gateway ID, security group IDs (exported via `terraform output --json`).
- Track values in Chapter 1 summary for quick reuse in Chapter 2 provisioning scripts.

## Follow-up
- Supply actual admin CIDR(s) and optional NodePort sources when applying Terraform.
- After EC2 provisioning, confirm outbound internet from private subnets via bastion (curl to public endpoints).
