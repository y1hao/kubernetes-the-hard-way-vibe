# Cluster Core Add-ons Overview

## Installed Components
- **CoreDNS** — `coredns/coredns:v1.11.1`, deployed in `kube-system` with Service VIP `10.32.0.10` for `cluster.local` DNS resolution.
- **Metrics Server** — `registry.k8s.io/metrics-server/metrics-server:v0.7.2`, serving the `metrics.k8s.io` API for node/pod metrics via TLS-authenticated kubelet scraping.

## Operator Commands
- DNS health:
  ```bash
  chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig -n kube-system exec deploy/coredns -c coredns -- nslookup kubernetes.default
  ```
- Metrics availability:
  ```bash
  chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig top nodes
  ```

## RBAC Notes
- Administrative access continues to rely on the built-in `system:masters` group; no additional cluster-admin bindings were created in this chapter.

## Artifacts
- CoreDNS manifest: `chapter9/manifests/coredns.yaml`
- Metrics Server manifest: `chapter9/manifests/metrics-server.yaml`
