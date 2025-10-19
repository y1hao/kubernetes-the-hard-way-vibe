# Chapter 9 — Core Add-ons

This chapter deploys cluster-critical add-ons: CoreDNS for service discovery and Metrics Server for resource metrics. All manifests live in `chapter9/manifests/` and are rendered with cluster-specific values (service CIDR, image pins, TLS settings).

## Status — 2025-10-18
- CoreDNS and Metrics Server are deployed and healthy; `k top nodes` returns metrics for all nodes.
- kube-apiserver runs with the aggregation flags, including `--enable-aggregator-routing=true`, and trusts the front-proxy client cert at `/var/lib/kubernetes/front-proxy-client.pem`.
- `k get apiservice v1beta1.metrics.k8s.io` reports `Available=True`; the aggregation layer is functional.

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
3. Re-distribute the updated Chapter 5 assets so the control-plane nodes pick up kube-proxy, containerd, kubelet, and the refreshed front-proxy materials, then rerun the bootstrap:
   ```bash
   ./chapter5/scripts/distribute_control_plane.sh --nodes cp-a cp-b cp-c --ssh-key chapter1/kthw-lab
   for ip in 10.240.16.10 10.240.48.10 10.240.80.10; do
     ssh -i chapter1/kthw-lab ubuntu@${ip} 'sudo bash -s' < chapter5/scripts/bootstrap_control_plane.sh
   done
   ```
   _Adjust the SSH key and node IPs to match your environment._
4. Apply Metrics Server assets (runs on hostNetwork so control-plane ClusterIP lookups succeed):
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

## Troubleshooting
- If `v1beta1.metrics.k8s.io` reports `FailedDiscoveryCheck`, confirm the control-plane nodes host the front-proxy CA/client PEMs and `kube-apiserver.env` includes the `--requestheader-*`, `--proxy-client-*`, and `--enable-aggregator-routing=true` flags.
- Re-run `KUBECTL_BIN=k bash chapter9/scripts/ensure_requestheader_configmap.sh` after updating the front-proxy CA so the `extension-apiserver-authentication` ConfigMap carries the latest bundle.
- Restart the metrics-server deployment (`k -n kube-system rollout restart deploy/metrics-server`) to pick up ConfigMap changes before re-testing `k top nodes`.

## Notes
- CoreDNS service IP is pinned to `10.32.0.10`; ensure kubelets retain `--cluster-dns=10.32.0.10`.
- Metrics Server talks to kubelets on their secure port using the CA from Chapter 3; no insecure flags are set.
- Clean up the helper pod after validation with `k delete -f chapter9/validation/test-client.yaml`.
- BusyBox `nslookup` prefers fully qualified names; use `kubernetes.default.svc.cluster.local` for validation.
- If the Chapter 3 CA lives outside the repo, override it with `CA_PATH=/path/to/ca.pem KUBECTL_BIN=k bash chapter9/scripts/ensure_requestheader_configmap.sh`. The script updates both the request-header and client CA data expected by the aggregator.
- Ensure containerd/kubelet/kube-proxy are running on all control-plane nodes before validating metrics; without them, the apiserver cannot reach ClusterIP-backed aggregated APIs.
- The requestheader ConfigMap relies on the front-proxy CA generated in Chapter 3 (`chapter3/pki/front-proxy/`); regenerate and redistribute those assets before rerunning the kube-apiserver bootstrap.
- Administrative access continues to rely on the default `system:masters` binding.
