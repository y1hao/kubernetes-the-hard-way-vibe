# Chapter 10 Execution Plan — Internet-Facing App via ALB

## Prerequisites
1. Chapter 1 Terraform state is available to supply VPC, subnet, and security group IDs.
2. Chapter 2 Terraform state exposes worker instance IDs and availability zones.
3. Workers remain healthy (`kubectl get nodes`) and CoreDNS/metrics server from Chapter 9 are operational.
4. Local machine (and bastion) have Terraform 1.13.3 and AWS credentials scoped for ALB provisioning.

## Execution Steps
1. **Scaffold chapter artifacts**
   - Create `chapter10/terraform/` with provider configuration, remote-state data sources for Chapters 1 & 2, and local tagging helpers.
   - Add `chapter10/manifests/` for Kubernetes assets and `chapter10/README.md` for operator guidance.
2. **Provision ALB infrastructure**
   - Define an ALB security group allowing inbound TCP/80 from the internet CIDR.
   - Update the existing worker security group (from Chapter 1 state) to allow TCP/30080 inbound from the ALB security group only.
   - Create an ALB across the public subnets, an HTTP target group on port 30080, register `worker-a` and `worker-b` instances, and attach an HTTP listener on port 80 with `/` health checks.
   - Expose the ALB DNS name via Terraform outputs for documentation and validation.
3. **Author nginx workload**
   - Render `chapter10/manifests/nginx-deployment.yaml` with env vars sourced from the Downward API (`spec.nodeName`, `status.hostIP`). Use a shell entrypoint to populate `/usr/share/nginx/html/index.html` with node identity prior to launching nginx.
   - Create `chapter10/manifests/nginx-service.yaml` as a `NodePort` Service pinned to 30080/tcp.
   - Document apply/delete commands and validation steps in `chapter10/README.md`, including expected response format from the ALB.
4. **Terraform hygiene**
   - Run `terraform fmt`, `terraform validate`, and `terraform plan` in `chapter10/terraform/`; share the plan and await user approval before apply.
   - After approval, request the user run `terraform apply` from the bastion (or locally if preferred).
5. **Deploy workload**
   - Provide `kubectl apply -f chapter10/manifests/` commands for execution on the bastion, ensuring pods schedule on the workers and report Ready.
6. **Validation**
   - Instruct the operator to curl the ALB DNS name and observe responses alternating between worker nodes (`Served by <node>/<IP>`).
   - Confirm ALB target group health checks pass and that security group changes took effect (no direct access to 30080 from arbitrary sources).
7. **Project docs**
   - Append Chapter 10 summary to the repo `README.md` once validation completes.
   - Capture validation notes or caveats in `chapter10/README.md` and, if needed, `chapter10/validation/` assets.

## Validation Steps
1. `terraform plan` in `chapter10/terraform/` shows only the ALB stack resources and security group rule updates.
2. ALB target group reports both worker instances healthy (`aws elbv2 describe-target-health`).
3. `kubectl get pods -n default -l app=chapter10-nginx` returns Ready pods on both workers.
4. `curl http://<alb-dns-name>` returns `Served by worker-*/10.240.*.*`, alternating between nodes over several requests.
5. Direct access to worker NodePort from outside the ALB (e.g., `curl http://<worker-public-ip>:30080`) fails, confirming SG scoping.
