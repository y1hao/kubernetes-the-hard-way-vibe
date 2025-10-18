# Metrics Server Aggregation — WIP

## Current State (2025-10-18)

- Control-plane nodes run kubelet/containerd/kube-proxy and are Ready; Calico DaemonSet scheduled on cp-a/b/c.
- Metrics Server runs with `hostNetwork: true`, mounting kubeconfig and client cert secrets and successfully scraping kubelets (validated via debug pod curl).
- RBAC binds both the `metrics-server` ServiceAccount and the TLS user `system:metrics-server` to the `system:metrics-server` ClusterRole.
- Front-proxy CSR templates added; manifest/bootstrap expect `/var/lib/kubernetes/front-proxy-{ca,client,client-key}.pem` and kube-apiserver env includes the `--requestheader-*` and `--proxy-client-*` flags.
- Security groups now allow 10250/4443 between control-plane nodes and 4443 from control-plane to workers.
- Requestheader ConfigMap generation script updated to use front-proxy CA; metrics-server manifest mounts secrets as directories via subPath.

## Blocking Issue

- `kubectl get apiservice v1beta1.metrics.k8s.io` still reports `FailedDiscoveryCheck` with 403 (“bad status from https://10.32.0.229:443/apis/metrics.k8s.io/v1beta1”).
- Metrics server logs show only readiness probe warnings (“no metrics to serve”); no explicit errors from aggregated requests.
- Need to confirm front-proxy certs are generated and distributed, apiserver restarted with new flags, and capture why metrics-server returns 403 to the apiserver.

## Next Steps

1. Generate front-proxy CA/client via cfssl and redistribute control-plane assets; rerun bootstrap to place `/var/lib/kubernetes/front-proxy-*.pem`.
2. Run `KUBECTL_BIN=k bash chapter9/scripts/ensure_requestheader_configmap.sh` to refresh the ConfigMap with client/front-proxy CAs.
3. Redeploy metrics-server and ensure pod uses the updated secrets.
4. Increase metrics-server verbosity (add `--v=4`) or inspect apiserver audit/logs to see the exact 403 reason.
5. Re-test: `k get apiservice v1beta1.metrics.k8s.io`, `k top nodes`.
