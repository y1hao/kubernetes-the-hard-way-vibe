# Chapter 13 Execution Plan — Public API Exposure

1. Create the `chapter13/` structure (terraform/, docs/, kubeconfigs/) and placeholder documentation files required for this chapter.
2. Author Terraform configuration that pulls Chapter 1 & 2 remote state, defines the dedicated public API security group with admin CIDR ingress, provisions the public NLB/target group/listener, and attaches the control-plane instances while adding the control-plane SG rule to accept traffic from the new NLB.
3. Emit Terraform outputs for the public NLB DNS name, security group ID, and target group ARN, and document the required variables/inputs inside the Terraform stack.
4. Run `terraform fmt`, `terraform validate`, and `terraform plan` for Chapter 13 and share the plan results for approval.
5. Provide the `terraform apply` command for you to run and pause further work until you confirm the infrastructure is in place.
6. Append the public NLB DNS name to `chapter3/pki/apiserver/apiserver-hosts.json` and regenerate the kube-apiserver certificate/key with `cfssl`, replacing the existing artifacts.
7. Prepare guidance and helper artifacts for deploying the refreshed certificate/key to each control-plane node and restarting kube-apiserver via bastion-executed commands.
8. Generate `chapter13/kubeconfigs/admin-public.kubeconfig` that targets the public NLB endpoint and document its distribution workflow.
9. Fold CIDR allowlist rotation guidance into `chapter13/README.md`, relying on Terraform state/outputs instead of separate docs.
10. Record the validation checklist and exact commands in the Chapter 13 docs to confirm public kubectl access, allowlist enforcement, and control-plane resilience.
11. Update the repo `README.md` with the Chapter 13 summary once validations complete.
