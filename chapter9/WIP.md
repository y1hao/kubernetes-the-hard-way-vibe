# Metrics Server Aggregation — WIP

**Status:** Completed on 2025-10-18; retained for reference.

## Current State (2025-10-18)

- Control-plane nodes run kubelet/containerd/kube-proxy and are Ready; Calico DaemonSet scheduled on cp-a/b/c.
- Metrics Server runs with `hostNetwork: true`, mounting kubeconfig and client cert secrets and successfully scraping kubelets (validated via debug pod curl).
- RBAC binds both the `metrics-server` ServiceAccount and the TLS user `system:metrics-server` to the `system:metrics-server` ClusterRole.
- Front-proxy CSR templates added; manifest/bootstrap expect `/var/lib/kubernetes/front-proxy-{ca,client,client-key}.pem` and kube-apiserver env includes the `--requestheader-*` and `--proxy-client-*` flags.
- Security groups now allow 10250/4443 between control-plane nodes and 4443 from control-plane to workers.
- Requestheader ConfigMap generation script updated to use front-proxy CA; metrics-server manifest mounts secrets as directories via subPath.

## Blocking Issue

- `kubectl get apiservice v1beta1.metrics.k8s.io` reported `FailedDiscoveryCheck` with 403/401 responses from the metrics-server endpoint.
- Metrics server logs showed readiness probe noise but no explicit aggregated auth errors, pointing at missing aggregation-layer trust between the apiserver and metrics-server.

## Immediate Plan (Executed)

1. **Create front-proxy materials** — Generated the front-proxy CA/client with `cfssl`, kept keys local, and copied the PEMs to the bastion.
2. **Distribute and restart kube-apiserver** — Re-ran `./chapter5/scripts/distribute_control_plane.sh --nodes cp-a cp-b cp-c --ssh-key chapter1/kthw-lab` then bootstrapped each control-plane (`sudo bash bootstrap_control_plane.sh`) so `/etc/kubernetes/kube-apiserver/kube-apiserver.env` rendered the aggregator flags, including `--enable-aggregator-routing=true`.
3. **Refresh aggregator trust bundle** — Executed `CLIENT_CA_PATH=chapter3/pki/ca/ca.pem PROXY_CA_PATH=chapter3/pki/front-proxy/front-proxy-ca.pem KUBECTL_BIN=k bash chapter9/scripts/ensure_requestheader_configmap.sh` and verified the ConfigMap carried both CA bundles.
4. **Restart metrics-server** — Triggered `k -n kube-system rollout restart deploy/metrics-server` and waited for the deployment to become ready.
5. **Validate aggregation** — `k get apiservice v1beta1.metrics.k8s.io -o wide` now reports `Available=True`; `k top nodes` returns node metrics.

## Open Questions

- None; chapter execution closed.

## Outcome

- Aggregation layer healthy as of 2025-10-18 23:30 UTC; apiserver logs no longer emit 401 discovery failures.
- Metrics applied; continue normal Chapter 9 cleanup (remove validation pod, update chapter summary).
