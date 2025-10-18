# Chapter 7 Worker Enablement

## Script: `enable_workers.sh`

One-stop helper to push Chapter 7 artifacts to a worker node and enable the runtime stack.

### Prerequisites
- Run from repository root so Chapter 3 PKI and Chapter 7 binaries/configs resolve.
- Control plane API reachable at `api.kthw.lab:6443`.
- SSH key from Chapter 1 available (defaults to `chapter1/kthw-lab`).

### Usage
```bash
KTHW_SSH_KEY="$(pwd)/chapter1/kthw-lab" \
KTHW_SSH_OPTS="-o HostName=10.240.16.20 -o User=ubuntu" \
./chapter7/scripts/enable_workers.sh worker-a
```

Adjust `HostName`/`User` per node or create SSH config aliases. Repeat for `worker-b` with `HostName=10.240.48.20`.

### Steps performed
1. Prepares remote directories under `/etc`, `/var/lib`, and a staging area.
2. Copies binaries, containerd/crictl archives, configs, kubeconfigs, and certs.
3. Installs binaries and configs into place, unpacks tarballs.
4. Reloads systemd, enables, and starts `containerd`, `kubelet`, `kube-proxy`.
5. Shows service status and verifies node registration with `kubectl get nodes`.
