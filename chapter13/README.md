# Chapter 13 — Public API Exposure

This chapter publishes the kube-apiserver through an internet-facing AWS Network Load Balancer so approved operators can run `kubectl` from outside the VPC. Access is gated by a dedicated security group that only allows CIDRs supplied at apply time, and the apiserver certificates/kubeconfigs are rotated to trust the public endpoint while leaving the bastion workflow intact as fallback.

## Terraform Workflow
Run all commands from the repo root. Substitute your current public IP whenever you execute plan/apply (the helper uses `curl` so nothing is written to disk):

```bash
bin/terraform -chdir=chapter13/terraform init
bin/terraform -chdir=chapter13/terraform validate
bin/terraform -chdir=chapter13/terraform plan \
  -var="admin_cidr_blocks=[\"$(curl -s https://ifconfig.me)/32\"]"
```

After review, apply the changes with the same `admin_cidr_blocks` value. Key outputs:

- `public_api_nlb_dns_name` — hostname to use in kubeconfigs
- `public_api_security_group_id` — SG that enforces the allowlist
- `public_api_target_group_arn` — for health checks / AWS CLI diagnostics

To inspect the current allowlist later:

```bash
bin/terraform -chdir=chapter13/terraform state show aws_security_group.public_api | rg "cidr_blocks"
```

## Kube-apiserver Certificate Rotation
Regenerate the apiserver cert (already done in this chapter) and follow the runbook to distribute and restart the service:

```bash
less chapter13/docs/apiserver-cert-rotation.md
```

The PKI manifest now pins ownership of the apiserver cert, key, and encryption config to `kube-apiserver`, so the distribution script handles permissions automatically.

## Public Admin Kubeconfig
A public-facing kubeconfig is generated at `chapter13/kubeconfigs/admin-public.kubeconfig`. It reuses the Chapter 3 admin credentials and points to the public NLB hostname. Distribute it to trusted operators and set `KUBECONFIG` when running commands from the internet:

```bash
export KUBECONFIG=$(pwd)/chapter13/kubeconfigs/admin-public.kubeconfig
kubectl get --raw=/livez
```

Keep the original `chapter5/kubeconfigs/admin.kubeconfig` for bastion access.

## Allowlist Updates
To rotate admin CIDRs, rerun Terraform with the new list:

```bash
bin/terraform -chdir=chapter13/terraform apply \
  -var='admin_cidr_blocks=["203.0.113.42/32","198.51.100.0/24"]'
```

Terraform will update the security group rule in place. Removing your own IP should immediately sever access (see validation below).

## Validation Checklist
1. **Public health check** — From a trusted network (using the new kubeconfig), verify:
   ```bash
   kubectl --kubeconfig chapter13/kubeconfigs/admin-public.kubeconfig get --raw=/livez
   ```
2. **Allowlist enforcement** — Temporarily remove your CIDR from `admin_cidr_blocks`, reapply, and confirm the same command fails with a timeout. Add the CIDR back and reapply to restore access.
3. **NLB resilience** — Stop kube-apiserver on one control plane (`sudo systemctl stop kube-apiserver`) and confirm the NLB endpoint remains reachable before restarting the service.
4. **Certificate SAN audit** — On any control plane:
   ```bash
   sudo openssl x509 -in /var/lib/kubernetes/apiserver.pem -noout -text | grep -F "kthw-public-api"
   ```

## Operational Notes
- The public NLB shares the same targets as the internal control-plane NLB; keep both healthy during upgrades.
- Record the NLB DNS name in your secrets manager if you need to distribute it beyond git.
- Cleanup (Chapter 14) must remove the NLB, its security group, and DNS consumers before tearing down the VPC.
