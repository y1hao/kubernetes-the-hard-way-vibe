# Cluster Core Add-ons Overview

## Installed Components
- **CoreDNS** — `coredns/coredns:v1.11.1`, deployed in `kube-system` with Service VIP `10.32.0.10` for `cluster.local` DNS resolution.
- **Metrics Server** — `registry.k8s.io/metrics-server/metrics-server:v0.7.2`, serving the `metrics.k8s.io` API for node/pod metrics via TLS-authenticated kubelet scraping.

## Operator Commands
- DNS health:
  ```bash
  k exec dns-metrics-check -- nslookup kubernetes.default.svc.cluster.local
  ```
  Short names (e.g., `kubernetes.default`) may return NXDOMAIN inside BusyBox; always use the FQDN.
- Metrics availability:
  ```bash
  k top nodes
  ```
- Regenerate trust data if needed:
  ```bash
  KUBECTL_BIN=k bash chapter9/scripts/ensure_requestheader_configmap.sh
  ```
- The APIService is configured with `insecureSkipTLSVerify: true` to tolerate Metrics Server's self-signed certificate; switch to a signed cert before tightening this setting.
- Refresh aggregator trust bundle when needed:
  ```bash
  KUBECTL_BIN=k bash chapter9/scripts/ensure_requestheader_configmap.sh
  ```

> Ensure the helper pod from `chapter9/validation/test-client.yaml` is running before issuing DNS checks.

## RBAC Notes
- Administrative access continues to rely on the built-in `system:masters` group; no additional cluster-admin bindings were created in this chapter.

## Artifacts
- CoreDNS manifest: `chapter9/manifests/coredns.yaml`
- Metrics Server manifest: `chapter9/manifests/metrics-server.yaml`
