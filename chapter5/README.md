# Chapter 5 — Kubernetes Control Plane

## Overview
Chapter 5 focuses on staging the upstream Kubernetes v1.31.1 control plane binaries (kube-apiserver, kube-controller-manager, kube-scheduler, kubectl), pushing their configuration, and bootstrapping the three control plane nodes (`cp-a`, `cp-b`, `cp-c`). The work builds on the ADR 005 decisions, the Chapter 3 PKI, and the Chapter 4 etcd cluster.

## Work Completed
- Staged the v1.31.1 control plane binaries under `chapter5/bin/` and authored env files plus systemd units in `chapter5/config/` and `chapter5/systemd/`.
- Iterated on `bootstrap_control_plane.sh` to copy the etcd CA, normalise ownership, render node-specific settings, and restart the services idempotently.
- Added request-header CA flags for controller-manager and scheduler, removed the deprecated scheduler `--port` flag, and ensured kube-apiserver references the shared PKI layout under `/var/lib/kubernetes`.
- Rolled kube-proxy plus the full kubelet/containerd stack onto the control-plane nodes so they participate in the pod network; manifests now ship the runtime binaries/configs and the bootstrap script enables containerd, kubelet, and kube-proxy alongside the core control-plane services.
- Added the aggregator front-proxy CA/client certificates and wired the kube-apiserver `--requestheader-*`/`--proxy-client-*` flags so aggregated APIs like metrics-server can authenticate proxied requests.
- Resolved bring-up regressions by:
  - Dropping the obsolete `--cloud-provider=none` flag from kube-controller-manager.
  - Converting controller-manager and scheduler systemd units to `Type=exec` so systemd stops timing them out.
  - Fixing kube-apiserver’s `--advertise-address` templating and restoring proper certificate ownership to stop timeout/permission errors.
- Distributed the refreshed assets and re-ran the bootstrap workflow on all three control plane nodes, verifying service health via `/healthz?verbose` on each node.

## Bastion Command Log
All commands were executed from the bastion host with the repository checked out at `~/kubernetes-the-hard-way-vibe`.

### Common preparation
```
cd ~/kubernetes-the-hard-way-vibe
```

### cp-a bootstrap
```
./chapter5/scripts/distribute_control_plane.sh --nodes cp-a --ssh-key chapter1/kthw-lab
ssh -i chapter1/kthw-lab ubuntu@10.240.16.10 'sudo bash -s' < chapter5/scripts/bootstrap_control_plane.sh
ssh -i chapter1/kthw-lab ubuntu@10.240.16.10 'sudo systemctl status kube-apiserver kube-controller-manager kube-scheduler --no-pager'
ssh -i chapter1/kthw-lab ubuntu@10.240.16.10 'sudo kubectl --kubeconfig /var/lib/kubernetes/admin.kubeconfig get --raw=/healthz?verbose'
```

### cp-b bootstrap
```
ssh -i chapter1/kthw-lab ubuntu@10.240.48.10 'sudo bash -c '\''for u in kube-apiserver kube-controller-manager kube-scheduler; do id "$u" &>/dev/null || useradd --system --home /var/lib/$u --shell /usr/sbin/nologin --create-home "$u"; done'\''
./chapter5/scripts/distribute_control_plane.sh --nodes cp-b --ssh-key chapter1/kthw-lab
ssh -i chapter1/kthw-lab ubuntu@10.240.48.10 'sudo bash -s' < chapter5/scripts/bootstrap_control_plane.sh
ssh -i chapter1/kthw-lab ubuntu@10.240.48.10 'sudo systemctl status kube-apiserver kube-controller-manager kube-scheduler --no-pager'
ssh -i chapter1/kthw-lab ubuntu@10.240.48.10 'sudo kubectl --kubeconfig /var/lib/kubernetes/admin.kubeconfig get --raw=/healthz?verbose'
```

### cp-c bootstrap
```
ssh -i chapter1/kthw-lab ubuntu@10.240.80.10 'sudo bash -c '\''for u in kube-apiserver kube-controller-manager kube-scheduler; do id "$u" &>/dev/null || useradd --system --home /var/lib/$u --shell /usr/sbin/nologin --create-home "$u"; done'\''
./chapter5/scripts/distribute_control_plane.sh --nodes cp-c --ssh-key chapter1/kthw-lab
ssh -i chapter1/kthw-lab ubuntu@10.240.80.10 'sudo bash -s' < chapter5/scripts/bootstrap_control_plane.sh
ssh -i chapter1/kthw-lab ubuntu@10.240.80.10 'sudo systemctl status kube-apiserver kube-controller-manager kube-scheduler --no-pager'
ssh -i chapter1/kthw-lab ubuntu@10.240.80.10 'sudo kubectl --kubeconfig /var/lib/kubernetes/admin.kubeconfig get --raw=/healthz?verbose'
```

## Validation
- `systemctl status kube-apiserver kube-controller-manager kube-scheduler --no-pager` reports `active (running)` on `cp-a`, `cp-b`, and `cp-c`.
- `kubectl --kubeconfig /var/lib/kubernetes/admin.kubeconfig get --raw=/healthz?verbose` returns healthy subchecks from each control-plane node.
- Controller-manager and scheduler logs show successful leader elections without timeout or permission errors.

## Next Steps
- Chapter 6 will introduce an internal load balancer and a stable API endpoint; once in place, regenerate the admin kubeconfig to target the LB DNS name and repeat the health checks from the bastion.
- Keep the systemd units and bootstrap script aligned with future configuration changes by re-running the distribution workflow whenever the control plane assets evolve.
