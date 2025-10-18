# Chapter 9 Execution Plan — Core Add-ons

## Execution Steps
1. Create `chapter9/` directory with `manifests/`, `docs/`, and `validation/` subfolders to host add-on assets.
2. Download the upstream CoreDNS manifest, tailor cluster-specific settings (image tag `coredns/coredns:v1.11.1`, service IP `10.32.0.10`, domain) and save as `chapter9/manifests/coredns.yaml`.
3. Fetch the upstream Metrics Server deployment, adjust flags for secure kubelet scraping and reference our CA bundle, then save as `chapter9/manifests/metrics-server.yaml`.
4. Document deployment commands, rollback notes, and validation guidance in `chapter9/README.md`, linking to the rendered manifests.
5. Produce `chapter9/docs/cluster-info.md` summarizing installed add-ons, DNS VIP, and operator commands for discovery and metrics checks.
6. Capture validation helpers under `chapter9/validation/` (e.g., a simple test pod manifest if needed) and document `nslookup kubernetes.default` plus `kubectl top` procedures.

## Validation Steps
1. `kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig exec -n kube-system deploy/coredns -c coredns -- nslookup kubernetes.default` resolves to the API service IP.
2. `kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig top nodes` returns metrics for all nodes.
