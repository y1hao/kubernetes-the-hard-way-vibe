# Chapter 7 Worker Enablement

## Script: `enable_workers.sh`

One-stop helper to push Chapter 7 artifacts to a worker node and enable the runtime stack.

### Prerequisites
- SSH config aliases for `worker-a`, `worker-b` (via bastion `~/.ssh/config`).
- Local environment possesses Chapter 3 PKI and Chapter 7 binaries/configs (run from repo root).
- Control plane API reachable at `api.kthw.lab:6443`.

### Steps performed
1. Prepares remote directories under `/etc`, `/var/lib`, and a staging area.
2. Copies binaries, containerd/crictl archives, configs, kubeconfigs, and certs.
3. Installs binaries and configs into place, unpacks tarballs.
4. Reloads systemd, enables, and starts `containerd`, `kubelet`, `kube-proxy`.
5. Shows service status and verifies node registration with `kubectl get nodes`.

Run per node:

```bash
./chapter7/scripts/enable_workers.sh worker-a
./chapter7/scripts/enable_workers.sh worker-b
```

Review service status (`systemctl status ...`) and kubelet logs if the node fails to register.
