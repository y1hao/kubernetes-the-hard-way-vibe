# Chapter 10 — Internet-Facing Application

This chapter introduces an AWS Application Load Balancer fronting a simple nginx deployment exposed via a Kubernetes NodePort. The ALB mirrors the operator's workplace setup while keeping implementation lightweight for the lab.

## Assets
- `terraform/`: Provisions the ALB, security group rules, target group attachments, and exposes the ALB DNS name.
- `manifests/`: Contains the nginx `Deployment` and `Service` with Downward API wiring so each pod reports which worker served the request.

## Runbook
1. From the repo root: `bin/terraform -chdir=chapter10/terraform init`
2. Run hygiene commands:
   - `bin/terraform -chdir=chapter10/terraform fmt`
   - `bin/terraform -chdir=chapter10/terraform validate`
   - `bin/terraform -chdir=chapter10/terraform plan`
3. Review the plan output, then (on confirmation) apply it: `bin/terraform -chdir=chapter10/terraform apply`
4. Capture the ALB DNS name: `bin/terraform -chdir=chapter10/terraform output -raw alb_dns_name`
5. Deploy the workload from the bastion:
   - `k apply -f chapter10/manifests/`
6. Validate:
   - `k get pods -l app=chapter10-nginx`
   - `curl http://$(bin/terraform -chdir=chapter10/terraform output -raw alb_dns_name)` (repeat to watch node identity alternate)
   - `aws elbv2 describe-target-health --target-group-arn $(bin/terraform -chdir=chapter10/terraform output -raw alb_target_group_arn)`

## Cleanup
- Remove the workload: `k delete -f chapter10/manifests/`
- Destroy the ALB stack when no longer required: `bin/terraform -chdir=chapter10/terraform destroy`
