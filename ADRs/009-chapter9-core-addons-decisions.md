# ADR: Chapter 9 Core Add-ons Decisions

## Status
Accepted

## Context
Chapter 9 introduces the first set of Kubernetes add-ons that make the cluster operationally useful: CoreDNS for service discovery, the optional-but-recommended Metrics Server, and baseline access bindings for administrators. Previous chapters already established the cluster's service CIDR (`10.32.0.0/24`) and Kubernetes version (`v1.31.1`). We needed to lock in add-on versions, service IP allocations, and scope of RBAC work before rendering manifests and composing the execution plan.

## Decision
- **CoreDNS version**: Use the upstream `coredns/coredns` image at `v1.11.1`, matching Kubernetes `v1.31.1` compatibility guidance and benefitting from recent bug fixes without jumping to an unreleased tag.
- **CoreDNS manifest source**: Base the deployment on the official upstream manifest, layering in cluster-specific settings (cluster domain `cluster.local`, service CIDR wiring, tolerations) while retaining the well-tested defaults.
- **Cluster DNS service IP**: Assign the `kube-dns` service the VIP `10.32.0.10`, the first stable slot in our service CIDR, keeping parity with kubelet configuration from earlier chapters.
- **Metrics Server**: Ship Metrics Server `v0.7.x` (pin `v0.7.2`) in this chapter so `kubectl top` works out of the box and to unblock future autoscaling demos; use the vendor deployment with TLS `--kubelet-insecure-tls` disabled and TLS roots sourced from Chapter 3.
- **Admin RBAC scope**: Rely on the existing `system:masters` mapping provided by the bootstrap process and document it in the operator notes. No additional cluster-admin bindings are required at this stage.
- **Artifacts layout**: Store rendered manifests and operator docs under a new `chapter9/` directory (`chapter9/manifests/`, `chapter9/README.md`, `chapter9/cluster-info.md`) to stay consistent with earlier chapters.

## Consequences
- Pinning CoreDNS `v1.11.1` keeps us aligned with upstream recommendations for Kubernetes `v1.31.x` and provides stability for service discovery testing.
- Reserving `10.32.0.10` for the DNS service matches kubelet DNS settings and avoids later reconfiguration.
- Including Metrics Server now validates end-to-end metrics collection and unlocks `kubectl top` during validation, at the cost of distributing one more manifest and certificate bundle.
- Documenting existing `system:masters` bindings avoids redundant RBAC manifests while still guiding operators on effective admin group usage.
- The standardized artifact layout enables future automation (Chapter 13) to find manifests predictably and maintain parity with previous chapter conventions.

## Follow-up
- Render CoreDNS and Metrics Server manifests with cluster-specific substitutions into `chapter9/manifests/`.
- Draft `chapter9/cluster-info.md` summarizing installed add-ons, DNS IP, and operator validation commands.
- Update `chapter9/README.md` with deployment steps, rollback notes, and validation guidance for `nslookup` and `kubectl top`.
