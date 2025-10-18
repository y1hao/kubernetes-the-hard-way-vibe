# Chapter 8 — Cluster Networking (Calico)

This chapter installs Calico v3.28.2 in VXLAN mode to wire up pod networking across the cluster. The manifest at `chapter8/calico.yaml` derives from the upstream Tigera release with the pod CIDR (`10.200.0.0/16`) embedded, IP-in-IP disabled, and VXLAN explicitly enabled. Calico's MTU remains auto-detected to track the ENA interface size automatically.

## Deployment Commands
Run the following from the bastion:

```bash
# Apply Calico manifest
./chapter5/bin/kubectl \
  --kubeconfig chapter5/kubeconfigs/admin.kubeconfig \
  apply -f chapter8/calico.yaml
```

> Ensure Chapter 1 security groups permit Calico control traffic on `tcp/179` (BGP) and `udp/4789` (VXLAN) between worker and control plane nodes before applying the manifest.

Expect the kubelet `NotReady` condition to clear once the Calico DaemonSet becomes ready on all nodes.

Before running exec/logs commands, ensure the kube-apiserver has kubelet proxy rights:

```bash
./chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig apply -f chapter8/manifests/kube-apiserver-to-kubelet-crb.yaml
```
## Validation Workflow
1. Confirm all components are healthy:
   ```bash
   ./chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig \
     get pods -n kube-system
   ```
   Ensure `calico-node` and `calico-kube-controllers` pods are Running/Ready. If `kubectl exec` fails to resolve node hostnames, run `chapter5/scripts/update_hosts_entries.sh` on the bastion to populate /etc/hosts entries.
2. Deploy the helper workloads from `chapter8/tests/` (created later in this chapter) to run cross-node connectivity checks.
3. Exec into each test pod to ping the peer pod IP and curl the test service ClusterIP to verify kube-proxy rules:
   ```bash
   ./chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig \
     exec deploy/net-spec -- ping -c3 <peer-pod-ip>
   ```
4. Review `calico-node` logs if readiness stalls:
   ```bash
   ./chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig \
     logs -n kube-system ds/calico-node -c calico-node --tail=50
   ```

## NetworkPolicy Notes
Baseline enforcement examples remain deferred to Chapter 11 (Security & Policies). For now, note that Calico is installed with policy support enabled; default pod isolation remains permissive until explicit NetworkPolicies are applied.

## Next Steps
Proceed with the test manifest creation and validation scripts outlined in `chapter8/TASKS.md` to complete this chapter.
