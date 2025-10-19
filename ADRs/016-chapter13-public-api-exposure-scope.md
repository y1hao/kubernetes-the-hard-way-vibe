# ADR: Chapter 13 Public API Exposure Scope

## Status
Accepted

## Context
We need to expose the kube-apiserver to trusted operators outside the VPC while keeping the posture aligned with the "hard way" architecture. Prior chapters provisioned an internal NLB (`kthw-api-nlb`) and private Route53 zone (`kthw.lab`). The public chapter now defines how remote admins reach the API without a bastion hop, while acknowledging constraints: no controllable public domain and a focus on enabling `kubectl` from approved networks.

## Decision
- Reuse the existing control plane NLB pattern with a new *public* Network Load Balancer spanning the public subnets, targeting the three control-plane instances on TCP 6443.
- Accept the managed AWS-generated NLB DNS name as the public endpoint instead of a custom Route53 record, since no public domain is available.
- Gate inbound traffic with a dedicated security group that permits TCP 6443 only from an administrator-managed allowlist CIDR set. This security group becomes the sole ingress path to the control-plane nodes for public access.
- Limit this chapter strictly to enabling remote `kubectl` access; optional enhancements such as AWS WAF integration, CloudWatch alarms, or centralized audit-log shipping are documented as out of scope unless they become prerequisites for connectivity.
- Document the workflow for updating kube-apiserver certificate SANs and regenerated kubeconfigs so operators use the NLB DNS name, keeping the bastion-based configs untouched for fallback.

## Consequences
- Operators can reach the API securely from approved networks using the AWS-provided NLB hostname without waiting for public DNS ownership.
- The new security group and allowlist introduce an operational process for managing CIDR rotations; lacking WAF/Shield means volumetric protections remain a future enhancement.
- Certificate and kubeconfig rotation must include the NLB hostname to avoid TLS errors, necessitating clear documentation and SOPs.

## Follow-up
- Capture a reusable procedure for updating the allowlist CIDRs and distributing refreshed configs.
- Revisit optional edge protections (WAF, Shield, CloudWatch alarms, audit pipelines) in later hardening chapters if requirements expand.
- Ensure Chapter 14 cleanup tooling knows how to tear down the public NLB, its security group, and related artifacts when decommissioning the cluster.
