# Chapter 2 Notes — EC2 Node Provisioning

## Terraform usage
- Initialise providers (first run): `bin/terraform -chdir=chapter2/terraform init`.
- Format and validate: `bin/terraform -chdir=chapter2/terraform fmt` and `bin/terraform -chdir=chapter2/terraform validate`.
- Preview changes: `bin/terraform -chdir=chapter2/terraform plan`.
- Apply: `bin/terraform -chdir=chapter2/terraform apply`.
- Destroy nodes only (network remains from Chapter 1): `bin/terraform -chdir=chapter2/terraform destroy`.

Terraform pulls Chapter 1 outputs from the local state at `chapter1/terraform/terraform.tfstate`, so keep that file accessible before running any Chapter 2 commands.

## Cloud-init templates
- Control planes: `chapter2/cloud-init/control-plane.yaml`.
- Workers: `chapter2/cloud-init/worker.yaml`.

Both templates share the same hardening steps (swap off, module loads, sysctl enforcement, package upgrades) but are split for future role-specific tweaks.

## Validation
- Ensure you can SSH to the bastion with the `kthw-lab` key.
- From the bastion (or any host with VPC reachability), run `chapter2/scripts/validate_nodes.sh`.
  - Optional overrides: `INVENTORY=/path/to/inventory.yaml`, `SSH_KEY_PATH=/path/to/key`, `SSH_USER=ubuntu`.
  - The script relies on `python3` and `PyYAML`; install with `pip install PyYAML` if missing.
- Successful output reports swap disabled, kernel modules present, and sysctl values aligned with Kubernetes prerequisites.

## Static IP map
- Control planes: `cp-a 10.240.16.10`, `cp-b 10.240.48.10`, `cp-c 10.240.80.10`.
- Workers: `worker-a 10.240.16.20`, `worker-b 10.240.48.20`. (IP `10.240.80.20` remains reserved for a future worker.)

## Follow-up
- Once the nodes are provisioned and validated, proceed to Chapter 3 to generate and distribute PKI material using the static host mapping above.
