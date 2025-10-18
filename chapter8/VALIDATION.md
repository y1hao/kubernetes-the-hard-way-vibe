# Chapter 8 Validation Checklist

1. **Calico components healthy**
   - `./chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig get pods -n kube-system`
   - Confirm `calico-node` DaemonSet has one Ready pod per node and `calico-kube-controllers` Deployment is Ready.
2. **Deploy connectivity fixtures**
   - `./chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig apply -f chapter8/tests/connectivity.yaml`
   - Wait for both `net-check` pods in `net-test` namespace to reach Ready state on separate nodes.
3. **Pod-to-pod ping**
   - Retrieve pod names/IPs: `./chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig get pods -n net-test -o wide`
   - From each pod: `./chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig exec -n net-test <pod> -- ping -c3 <peer-ip>`
4. **Service VIP curl**
   - `./chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig exec -n net-test <pod> -- curl -sS net-check.net-test.svc.cluster.local`
   - Expect HTTP success with JSON payload from agnhost netexec.
5. **Cleanup (optional)**
   - `./chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig delete -f chapter8/tests/connectivity.yaml`

If any checks fail, inspect `ds/calico-node` logs and node routes to verify VXLAN interfaces were created.
