# Chapter 7 — Worker Node Stack

This chapter stages the container runtime, kubelet, and kube-proxy on the worker nodes using upstream binaries aligned with Kubernetes v1.31.1.

## Validation Commands
Run these from the bastion after enabling each worker:

```bash
# Confirm services are active on worker-a
ssh -i "$(pwd)/chapter1/kthw-lab" ubuntu@10.240.16.20 'systemctl --no-pager status containerd kubelet kube-proxy'

# Check node registration (NotReady is expected until Calico/CNI is installed in Chapter 8)
./chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig get nodes

# Inspect kubelet logs if troubleshooting
ssh -i "$(pwd)/chapter1/kthw-lab" ubuntu@10.240.16.20 'sudo journalctl -u kubelet -n 40 --no-pager'
```

Repeat the SSH commands with `10.240.48.20` for `worker-b`.

## Known State
- Worker nodes appear as `NotReady` until the CNI plugin is applied in Chapter 8. This is expected.
- Container runtime uses `containerd` with systemd cgroups (`/etc/containerd/config.toml`).

Refer to `chapter7/scripts/enable_workers.sh` for the automated provisioning flow.
