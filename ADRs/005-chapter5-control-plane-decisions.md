# ADR: Chapter 5 Control Plane Decisions

## Status
Accepted

## Context
Chapter 5 covers installing and configuring the Kubernetes control plane binaries (`kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, and `kubectl`) on the three control plane nodes, plus ensuring the bastion has the tooling required for remote administration. We need a clear agreement on component versions, filesystem layout, runtime identities, and key configuration flags before implementing manifests and automation.

## Decision
- **Kubernetes release**: Standardise on upstream Kubernetes v1.31.1 for all control plane binaries and `kubectl`, aligning with the current stable stream while remaining compatible with the Chapter 4 etcd v3.5.12 cluster.
- **Filesystem layout**: Install binaries into `/usr/local/bin`; keep PKI, encryption config, and kubeconfigs under `/var/lib/kubernetes`; store component-specific configuration and environment files under `/etc/kubernetes/<component>/`.
- **System identities**: Run `kube-apiserver`, `kube-controller-manager`, and `kube-scheduler` under dedicated system users sharing the component name (home `/var/lib/<component>`, shell `/usr/sbin/nologin`).
- **kubectl distribution**: Stage `kubectl` v1.31.1 on each control plane node and the bastion host so operators can interact with the API without hopping through a control plane.
- **API server configuration**: Enable RBAC with `--authorization-mode=Node,RBAC` and configure admission plugins `NamespaceLifecycle,NodeRestriction,ServiceAccount,LimitRanger,ResourceQuota`. Other feature gates remain default.
- **Audit logging**: Defer configuring an audit policy and related flags for Chapter 5 to keep bring-up minimal; revisit in a later security-focused chapter.
- **Controller manager networking**: Configure `kube-controller-manager` with `--cluster-cidr=10.200.0.0/16`, `--service-cluster-ip-range=10.32.0.0/24`, enable node CIDR allocation (`--allocate-node-cidrs=true`), and leave `--cloud-provider=none`, matching the documented architecture.

## Consequences
- Staying on the latest 1.31 patch keeps us aligned with current Kubernetes features and security fixes; future upgrades must coordinate with etcd compatibility.
- The directory layout cleanly separates executables, mutable state, and configuration, simplifying distribution manifests and systemd unit design.
- Dedicated system users reduce blast radius for component compromise and clarify ownership for on-host assets.
- Installing `kubectl` on the bastion supports day-to-day administration without SSHing into the control plane, while keeping binaries aligned across hosts.
- The chosen RBAC and admission settings enforce baseline safety without introducing optional features we have not planned for yet.
- Deferring audit logging speeds initial bootstrap but postpones visibility into API activity until we revisit policy configuration.
- Explicit networking flags ensure controller-manager hands out pod and service addresses consistent with the Calico and service CIDRs defined earlier.

## Follow-up
- Author distribution manifests and systemd units that respect the approved layout and user ownership.
- Revisit audit logging when we tackle Chapter 11 (security and policies) or a dedicated observability chapter.
- Ensure future kube-apiserver flag expansions (e.g., feature gates) are documented and reviewed through new ADRs if they materially change behaviour.
