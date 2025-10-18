# ADR: Chapter 6 Stable API Access Decisions

## Status
Accepted

## Context
Chapter 6 introduces a highly available front door for the Kubernetes API so operators and components can talk to the control plane through a single, durable endpoint. We already have three control plane nodes (Chapter 2), PKI materials and SANs covering `api.kthw.lab` (Chapter 3), etcd-backed control plane services (Chapters 4 & 5), and security groups plus subnets from Chapter 1. We must agree on the load balancer approach, DNS domain, implementation tooling, health checks, and how this interacts with the existing host-level overrides before building automation.

## Decision
- **Load balancer**: Use the AWS internal Network Load Balancer spanning the three private subnets created in Chapter 1. Targets are the control plane instances on TCP 6443, matching the architecture baseline and avoiding extra moving parts.
- **DNS**: Create a private Route53 hosted zone for `kthw.lab` and publish an `api.kthw.lab` record pointing to the NLB. This leverages existing certificates, kubeconfigs, and node hostnames that already reference the `.kthw.lab` suffix.
- **Terraform layout**: Scaffold a dedicated `chapter6/terraform/` stack that consumes Chapter 1 (network) and Chapter 2 (instances) remote state to provision the NLB, target group attachments, and DNS record.
- **Health checks**: Configure the NLB target group to use a TCP health check on port 6443 for simplicity and compatibility with the apiserver’s native endpoint.
- **Host overrides**: Retain the `/etc/hosts` entry on the control plane nodes that maps `api.kthw.lab` to the local node IP for resiliency should DNS be unavailable. Document that the load-balanced hostname is still the canonical endpoint for clients.

## Consequences
- The internal NLB aligns with AWS-native resiliency while keeping the footprint minimal—no need to manage additional HAProxy nodes or failover logic.
- Reusing the `kthw.lab` zone avoids regenerating certificates or kubeconfigs; the private hosted zone gives us room for future internal records.
- A dedicated Terraform stack keeps Chapter 6 automation scoped and lets us reuse outputs from earlier chapters without cluttering prior modules.
- TCP health checks require no TLS termination or helper targets but provide only basic liveness; deeper HTTPS checks can be layered on later if desired.
- Leaving the `/etc/hosts` shim in place preserves local API availability for control plane maintenance, but we must be mindful that it bypasses the NLB when commands are run directly on those hosts.

## Follow-up
- Implement the Chapter 6 Terraform stack with variables/outputs documented for reuse in later chapters.
- Update operational docs to explain DNS propagation expectations and the control-plane `/etc/hosts` behaviour.
- Revisit health check depth and the `/etc/hosts` override during future hardening (e.g., Chapter 11) if requirements change.
