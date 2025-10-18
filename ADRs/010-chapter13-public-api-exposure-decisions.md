# ADR: Chapter 13 Public API Exposure Decisions

## Status
Accepted

## Context
Chapter 13 previously covered tooling and cleanup, which left the cluster’s external access pattern anchored to a bastion inside the VPC. We now need a documented path for operators to reach the kube-apiserver directly from the internet while keeping the footprint hardened. This requires reshaping the late chapters so the public exposure steps become first-class and the cleanup guidance moves into its own chapter.

## Decision
- Repurpose Chapter 13 to focus on publishing the kube-apiserver via a public-facing Network Load Balancer (or equivalent HA pair) that targets the three control plane nodes on TCP 6443.
- Constrain ingress with tight security groups, Route53 records, and certificate SAN updates so only approved CIDRs can reach `api.<cluster>.<domain>`.
- Layer optional edge protections—AWS WAF, CloudWatch alarms, and audit review—into the chapter to encourage operators to monitor the exposed surface.
- Create a new Chapter 14 dedicated to cleanup and teardown so lifecycle guidance remains available without diluting the public-access instructions.

## Consequences
- Operators gain a supported workflow to use `kubectl` from trusted networks without relying on the bastion host, reducing hop-by-hop friction.
- Security posture must be maintained through CIDR allowlists, certificate management, and observability, adding ongoing operational tasks.
- The SPEC’s chapter flow now surfaces exposure guidance before cleanup, which aligns with the typical build → expose → retire progression.

## Follow-up
- Extend Terraform/automation to provision the public NLB, DNS, and security group changes captured in Chapter 13.
- Rotate kube-apiserver certificates and kubeconfigs so they include the public hostname and distribute them via the remote access runbook.
- Update teardown tooling to remove any new public artifacts (NLB, Elastic IPs, Route53 records) when Chapter 14 procedures run.
