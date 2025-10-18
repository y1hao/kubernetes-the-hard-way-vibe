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
- Need to confirm front-proxy certs are generated and distributed, kube-apiserver is running with the aggregation flags, and capture why metrics-server returns 403 to the apiserver.

## Immediate Plan

1. **Create front-proxy materials** — On the workstation run `cfssl gencert -initca chapter3/pki/front-proxy/front-proxy-ca-csr.json | cfssljson -bare chapter3/pki/front-proxy/front-proxy-ca` and then issue the client cert with `cfssl gencert -ca=chapter3/pki/front-proxy/front-proxy-ca.pem -ca-key=chapter3/pki/front-proxy/front-proxy-ca-key.pem -config=chapter3/pki/ca/ca-config.json -profile=client chapter3/pki/front-proxy/front-proxy-client-csr.json | cfssljson -bare chapter3/pki/front-proxy/front-proxy-client` (keys stay untracked; scp them to the bastion afterwards).
2. **Distribute and restart kube-apiserver** — `./chapter5/scripts/distribute_control_plane.sh --nodes cp-a cp-b cp-c --ssh-key chapter1/kthw-lab` followed by `ssh -i chapter1/kthw-lab ubuntu@<cp-ip> "sudo systemctl daemon-reload && sudo systemctl restart kube-apiserver"` on each control-plane. Confirm `/etc/kubernetes/kube-apiserver/kube-apiserver.env` contains the `--requestheader-*`, `--proxy-client-*`, and `--enable-aggregator-routing=true` flags.
3. **Refresh aggregator trust bundle** — On the bastion run `CLIENT_CA_PATH=chapter3/pki/ca/ca.pem PROXY_CA_PATH=chapter3/pki/front-proxy/front-proxy-ca.pem KUBECTL_BIN=k bash chapter9/scripts/ensure_requestheader_configmap.sh` and re-check `k -n kube-system get cm extension-apiserver-authentication -o yaml` for the updated CA blocks.
4. **Restart metrics-server** — `k -n kube-system rollout restart deploy/metrics-server` and wait for `k -n kube-system rollout status deploy/metrics-server` to complete; inspect logs with `k -n kube-system logs deploy/metrics-server` if the rollout stalls.
5. **Validate aggregation** — `k get apiservice v1beta1.metrics.k8s.io -o wide` should flip to `Available=True`, then `k top nodes`/`k top pods -A` should respond.

## Open Questions

- If the apiserver still returns 403 after the above, capture `journalctl -u kube-apiserver -e` around the discovery query and enable metrics-server verbosity (`--v=4`) to capture the delegated auth decision.
