# ADR: Chapter 7 Worker Stack Decisions

## Status
Accepted

## Context
Chapter 7 covers the operating system and Kubernetes component setup on the worker nodes. We already provisioned the instances and base OS configuration via Chapter 2 cloud-init, generated all PKI material in Chapter 3, and aligned on control-plane versions and filesystem layout in Chapter 5. Before outlining the execution plan we need to finalise the worker-facing runtime, binary sourcing, identity handling, and proxy mode so subsequent automation is deterministic.

## Decision
- **Kubernetes binaries**: Stage upstream Kubernetes v1.31.1 `kubelet` and `kube-proxy` tarball artifacts under `chapter7/bin/` for distribution. Use the same version we run on the control plane to avoid skew and document SHA256 hashes in the upcoming manifest.
- **Container runtime stack**: Install containerd v1.7.14, runc v1.1.12, and crictl v1.31.1 from upstream release archives. Generate `/etc/containerd/config.toml` via `containerd config default`, then enforce `SystemdCgroup = true` and keep registry mirrors at defaults. Manage containerd with a dedicated systemd unit and socket activation as shipped upstream.
- **Kubelet identity & configuration**: Reuse the pre-issued per-node kubelet certificates and keys from Chapter 3, producing per-node `kubelet.kubeconfig` files that reference them (no TLS bootstrap). Author `/var/lib/kubelet/config.yaml` with `clusterDNS: ["10.32.0.10"]`, `clusterDomain: "cluster.local"`, webhook authn/authz pointing at the API server, `serializeImagePulls: false`, and default eviction thresholds. Launch the kubelet with explicit `--config`, `--kubeconfig`, `--cert-dir=/var/lib/kubelet/pki`, `--hostname-override=<short hostname>`, `--node-ip=<static IP>`, `--container-runtime-endpoint=unix:///run/containerd/containerd.sock`, and keep both certificate rotation flags disabled to avoid spurious CSR churn.
- **Kube-proxy mode**: Run kube-proxy in `iptables` mode for initial simplicity. Provide a dedicated kubeconfig that uses the Chapter 3 kube-proxy client certificate, and render a ConfigMap-style file pinned to iptables mode without IPVS-specific tuning. Systemd unit will execute the binary with `--config` pointing at that rendered file.
- **Artifact layout & distribution**: Store worker-specific configs under `chapter7/config/` (e.g., `containerd/config.toml`, `kubelet/config.yaml`, `kube-proxy/config.conf`) and document copy paths in a Chapter 7 distribution manifest alongside systemd unit files. Ensure runtime directories (`/var/lib/kubelet`, `/var/lib/containerd`) have the required ownership set during distribution steps.

## Consequences
- Aligning binaries with v1.31.1 prevents control-plane/worker skew and keeps future upgrades straightforward; staging them locally mirrors the Chapter 5 workflow.
- Containerd with systemd cgroups matches the control plane configuration and satisfies kubelet expectations while leaving room for registry overrides later if needed.
- Using the pre-generated certificates keeps Chapter 7 focused on installation mechanics; certificate rotation can be enabled in a later chapter once automated approvals exist.
- iptables-mode kube-proxy minimises moving parts for the initial bring-up, at the cost of deferring IPVS optimisations until we revisit networking enhancements.
- A well-defined artifact layout lets the upcoming TASKS plan reference concrete source and destination paths, streamlining bastion-driven distribution scripts.

## Follow-up
- Capture binary download URLs and checksum verification steps in the Chapter 7 implementation docs.
- Expand Chapter 2 cloud-init or Chapter 7 scripts to ensure required kernel modules (`br_netfilter`, etc.) remain loaded before kubelet startup.
- When we are ready to enable certificate rotation or IPVS mode, draft additional ADRs to record the changes and update affected manifests.
