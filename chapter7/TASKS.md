# Chapter 7 Execution Plan — Worker Node Stack

## Prerequisites
1. Confirm Chapter 2 Terraform outputs for worker node IPs/hostnames are available to drive per-node config templating.
2. Ensure Chapter 3 PKI artifacts for worker kubelets and kube-proxy (certs, keys) are accessible from the bastion.
3. Have Chapter 5 binaries directory available to mirror version alignment and record SHA256 hashes for the worker binaries.
4. Prepare bastion with `curl`, `sha256sum`, `tar`, and `systemctl` access for staging artifacts.

## Execution Steps
1. **Stage Kubernetes worker binaries**
   - Download upstream Kubernetes v1.31.1 release tarball, extract `kubelet` and `kube-proxy`, and place them under `chapter7/bin/` with recorded checksums.
2. **Stage container runtime artifacts**
   - Fetch containerd v1.7.14, runc v1.1.12, and crictl v1.31.1 archives into `chapter7/bin/`; verify checksums and unpack as needed for distribution.
3. **Author runtime and Kubernetes configs**
   - Render `containerd/config.toml` with `SystemdCgroup = true` under `chapter7/config/containerd/`.
   - Generate generic `kubelet/config.yaml` and per-node environment files capturing node IP/hostname bindings and kubeconfig paths under `chapter7/config/kubelet/`.
   - Produce kube-proxy config file and kubeconfig referencing the Chapter 3 client cert under `chapter7/config/kube-proxy/`.
4. **Create systemd service units**
   - Write unit files for containerd, kubelet, and kube-proxy under `chapter7/systemd/` referencing the staged binaries and config locations.
5. **Prepare distribution manifest**
   - Document copy targets, ownership, and permissions for binaries, configs, kubeconfigs, certs, and systemd units in `chapter7/manifest.yaml` to guide bastion-driven sync.
6. **Node enablement checklist**
   - Draft `chapter7/scripts/enable_workers.sh` (or equivalent instructions) to transfer artifacts, reload systemd, and enable/start services per worker.
7. **Validation steps**
   - Define commands to verify containerd/kubelet/kube-proxy status and confirm workers register with the API (`kubectl get nodes`).

## Validation Steps
1. `sha256sum --check` passes for all downloaded artifacts in `chapter7/bin/`.
2. `containerd config dump` on a worker reflects `SystemdCgroup = true` after deployment.
3. `systemctl status containerd kubelet kube-proxy` report active/running on both worker nodes.
4. `kubectl get nodes --kubeconfig chapter5/kubeconfigs/admin.kubeconfig` shows `worker-a` and `worker-b` in `Ready` state.
