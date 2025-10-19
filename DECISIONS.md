# Decisions Index

- [Chapter 1 AWS Network Preparation Decisions](ADRs/000-chapter1-network-prep-decisions.md) — Locked region, AZ layout, networking tools, and supporting constraints for Chapter 1 groundwork.
- [Chapter 2 Node Provisioning Decisions](ADRs/001-chapter2-node-provisioning-decisions.md) — Instance sizing, AMI sourcing, cloud-init scope, static IP map, and tooling for Chapter 2.
- [Chapter 2 Worker Sizing Adjustment](ADRs/002-chapter2-worker-sizing-adjustment.md) — Worker fleet right-sizing for cost optimisation.

- [Chapter 3 PKI Decisions](ADRs/003-chapter3-pki-decisions.md) — PKI tooling, CA structure, naming, and artifact layout for Chapter 3.
- [Chapter 4 etcd Decisions](ADRs/004-chapter4-etcd-decisions.md) — etcd release selection, data placement, TLS issuance strategy, and distribution tooling approach.
- [Chapter 5 Control Plane Decisions](ADRs/005-chapter5-control-plane-decisions.md) — Kubernetes release, filesystem layout, runtime identities, kubectl distribution, and core API/controller configuration flags.
- [Chapter 6 API Access Decisions](ADRs/006-chapter6-api-access-decisions.md) — Load balancer architecture, DNS zone selection, Terraform scope, health checks, and `/etc/hosts` handling for the control-plane endpoint.
- [Chapter 7 Worker Stack Decisions](ADRs/007-chapter7-worker-stack-decisions.md) — Worker binary sourcing, containerd stack, kubelet identity/config, and kube-proxy mode for Chapter 7 install.

- [Chapter 8 Cluster Networking Decisions](ADRs/008-chapter8-networking-decisions.md) — Calico release selection, VXLAN-only encapsulation, MTU handling, and artifact layout for Chapter 8 networking rollout.
- [Chapter 9 Core Add-ons Decisions](ADRs/009-chapter9-core-addons-decisions.md) — CoreDNS and Metrics Server baselines, DNS VIP allocation, RBAC scope, and artifact layout for Chapter 9.
- [Chapter 10 App Exposure Decisions](ADRs/012-chapter10-app-exposure-decisions.md) — ALB-based internet exposure strategy, listener scope, security group adjustments, and artifact layout for Chapter 10.
- [Chapter 13 Public API Exposure Decisions](ADRs/010-chapter13-public-api-exposure-decisions.md) — Public apiserver access pattern, security guardrails, and chapter reshuffle to surface exposure guidance.
- [Control Plane Node Agent Integration](ADRs/011-control-plane-node-agent-integration.md) — Enabled containerd/kubelet/kube-proxy on control-plane nodes so they join the pod network and support aggregated APIs.
