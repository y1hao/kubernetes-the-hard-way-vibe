# Chapter 9 — Core Add-ons

This chapter deploys cluster-critical add-ons: CoreDNS for service discovery and Metrics Server for resource metrics. All manifests live in `chapter9/manifests/` and are rendered with cluster-specific values (service CIDR, image pins, TLS settings).

## Prerequisites
- `chapter5/bin/kubectl` with `chapter5/kubeconfigs/admin.kubeconfig` reaches the cluster API.
- Chapter 8 networking (Calico) is healthy so pods can schedule and resolve DNS.
- The Metrics Server secret `metrics-server-kubelet-ca` exists in `kube-system`, containing the kubelet CA cert (`ca.crt`).

## Deployment Steps
1. Apply CoreDNS assets:
   ```bash
   k apply -f chapter9/manifests/coredns.yaml
   ```
2. Ensure the aggregator authentication ConfigMap is populated:
   ```bash
   KUBECTL_BIN=k bash chapter9/scripts/ensure_requestheader_configmap.sh
   ```
3. Apply Metrics Server assets:
   ```bash
   k apply -f chapter9/manifests/metrics-server.yaml
   ```

## Rollback
- Delete deployments and services if add-ons need to be removed:
  ```bash
  k delete -f chapter9/manifests/metrics-server.yaml
  k delete -f chapter9/manifests/coredns.yaml
  ```

## Validation
1. CoreDNS pods ready:
   ```bash
   k -n kube-system rollout status deploy/coredns
   ```
2. Launch the validation pod and wait for readiness:
   ```bash
   k apply -f chapter9/validation/test-client.yaml
   k wait pod/dns-metrics-check --for=condition=Ready --timeout=180s
   ```
3. DNS lookup resolves the Kubernetes service:
   ```bash
   k exec dns-metrics-check -- nslookup kubernetes.default.svc.cluster.local
   ```
4. Metrics Server serving metrics:
   ```bash
   k top nodes
   ```

## Notes
- CoreDNS service IP is pinned to `10.32.0.10`; ensure kubelets retain `--cluster-dns=10.32.0.10`.
- Metrics Server talks to kubelets on their secure port using the CA from Chapter 3; no insecure flags are set.
- Clean up the helper pod after validation with `k delete -f chapter9/validation/test-client.yaml`.
- BusyBox `nslookup` prefers fully qualified names; use `kubernetes.default.svc.cluster.local` for validation.
- If the Chapter 3 CA lives outside the repo, override it with `CA_PATH=/path/to/ca.pem KUBECTL_BIN=k bash chapter9/scripts/ensure_requestheader_configmap.sh`.
- Administrative access continues to rely on the default `system:masters` binding.
