# Chapter 9 — Core Add-ons

This chapter deploys cluster-critical add-ons: CoreDNS for service discovery and Metrics Server for resource metrics. All manifests live in `chapter9/manifests/` and are rendered with cluster-specific values (service CIDR, image pins, TLS settings).

## Prerequisites
- `chapter5/bin/kubectl` with `chapter5/kubeconfigs/admin.kubeconfig` reaches the cluster API.
- Chapter 8 networking (Calico) is healthy so pods can schedule and resolve DNS.
- The Metrics Server secret `metrics-server-kubelet-ca` exists in `kube-system`, containing the kubelet CA cert (`ca.crt`).

## Deployment Steps
1. Apply CoreDNS assets:
   ```bash
   chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig apply -f chapter9/manifests/coredns.yaml
   ```
2. Apply Metrics Server assets:
   ```bash
   chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig apply -f chapter9/manifests/metrics-server.yaml
   ```

## Rollback
- Delete deployments and services if add-ons need to be removed:
  ```bash
  chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig delete -f chapter9/manifests/metrics-server.yaml
  chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig delete -f chapter9/manifests/coredns.yaml
  ```

## Validation
1. CoreDNS pods ready:
   ```bash
   chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig -n kube-system rollout status deploy/coredns
   ```
2. Launch the validation pod and wait for readiness:
   ```bash
   chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig apply -f chapter9/validation/test-client.yaml
   chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig wait pod/dns-metrics-check --for=condition=Ready --timeout=120s
   ```
3. DNS lookup resolves the Kubernetes service:
   ```bash
   chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig exec dns-metrics-check -- /agnhost dig kubernetes.default
   ```
4. Metrics Server serving metrics:
   ```bash
   chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig top nodes
   ```

## Notes
- CoreDNS service IP is pinned to `10.32.0.10`; ensure kubelets retain `--cluster-dns=10.32.0.10`.
- Metrics Server talks to kubelets on their secure port using the CA from Chapter 3; no insecure flags are set.
- Clean up the helper pod after validation with `kubectl delete -f chapter9/validation/test-client.yaml`.
- Administrative access continues to rely on the default `system:masters` binding.
