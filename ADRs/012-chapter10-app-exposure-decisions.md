# ADR: Chapter 10 App Exposure Decisions

## Status
Accepted

## Context
Chapter 10 publishes a sample application to the internet. Previous chapters delivered a functional cluster with worker nodes, CoreDNS, and metrics. We now need an external load balancer, DNS approach, and workload shape that respect the project's "minimal AWS primitives" ethos while matching real-world operator experience. The SPEC suggested a Network Load Balancer, but the operator prefers mirroring workplace patterns that rely on an Application Load Balancer. We must confirm the ALB scope, listener settings, DNS expectations, Kubernetes service type, and how instance registration will be managed without introducing a Kubernetes Ingress controller.

## Decision
- **Load balancer type**: Use an AWS Application Load Balancer spanning the public subnets from Chapter 1. Register the worker instances directly in an HTTP target group that points to the application NodePort. This mirrors the operator's production environment.
- **Listeners**: Expose only HTTP on port 80 through the ALB. End-to-end TLS is deferred; nginx serves plain HTTP on NodePort 30080.
- **Health checks**: Employ HTTP health checks against `/` (nginx default welcome page). Target group deregisters a worker if the check fails.
- **DNS**: Do not create a public Route53 zone. Consumers will use the AWS-provided ALB DNS name; this keeps the chapter independent from domain ownership while still providing a stable endpoint.
- **Kubernetes Service**: Deploy nginx as a `Deployment` with a matching `Service` of type `NodePort` pinned to 30080/tcp. No Ingress controller is introduced in this chapter.
- **Security groups**: Attach a dedicated security group to the ALB allowing TCP/80 from the internet. Update the worker node security group (Chapter 1 output) to allow inbound TCP/30080 from the ALB security group, preserving least privilege.
- **Terraform layout**: Create a standalone `chapter10/terraform/` stack consuming Chapter 1 (network) and Chapter 2 (instances) remote state to provision the ALB, target group, listener, security group rules, and outputs.
- **Workload artifacts**: Store manifests under `chapter10/manifests/` and an operator runbook in `chapter10/README.md` aligned with prior chapters.

## Consequences
- Choosing an ALB aligns with workplace familiarity at the cost of extra configuration (security groups, HTTP health checks, instance registration). Future worker scaling requires Terraform updates unless automation is added later.
- Using the ALB DNS name avoids domain management but produces a long hostname; sharing friendly URLs would require Route53 in a later iteration.
- HTTP-only exposure keeps implementation lightweight, but browsers warn if TLS is expected. Upgrading to HTTPS later will require certificates and either ALB termination or application-side TLS.
- Registering instances directly maintains consistency with earlier "minimal automation" chapters, though it lacks dynamic discovery. An Ingress controller or auto-registering target groups can be layered on in future work.
- Documenting the security group adjustments ensures NodePort traffic remains controlled to ALB-only ingress instead of opening the cluster broadly.

## Follow-up
- Implement the Terraform stack and nginx manifests per this ADR.
- Note in documentation that scaling the worker pool necessitates a Terraform update to register new instances with the ALB.
- Revisit TLS termination and/or Kubernetes Ingress controllers in future chapters if richer routing or HTTPS is required.
