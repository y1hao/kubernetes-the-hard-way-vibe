# Chapter 11 Validation Guide

Run these checks from the bastion after applying Chapter 11 manifests.

## 1. Metrics Server on Workers
- Confirm the pod landed on a worker: `kubectl get pods -n kube-system -l k8s-app=metrics-server -o wide`
- Verify the Aggregated API responds: `kubectl top nodes`
- Inspect metrics-server logs if needed: `kubectl logs -n kube-system deploy/metrics-server --since=5m`

## 2. Admin Binding
- Non-admin kubeconfig (e.g. `chapter9/kubeconfigs/metrics-server.kubeconfig`): `kubectl --kubeconfig ... auth can-i create pods` → expect `no`.
- Admin kubeconfig still has full rights: `kubectl auth can-i '*' '*'` → `yes`.

## 3. Network Policies
1. Label an ingress namespace: `kubectl label namespace ingress-nginx networking.k8s.io/policy-role=ingress`
2. Deploy a test pod there and another in `default` with label `kthw.lab/allow-from-ingress=true`.
3. From the ingress pod, curl the `default` pod → success.
4. From an unlabeled namespace, the same curl should timeout/deny.

## 4. Kubelet Read-only Port Checks
- On each node (via SSH or daemonset): `sudo ss -ltnp | grep 10255` → no listener.
- `curl http://<node-ip>:10255/metrics` → connection refused.

## 5. Security Group Notes
- Document in ops runbook that metrics-server hostNetwork requires:
  - Control-plane ↔ worker TCP/10250 (kubelet).
  - Control-plane → worker TCP/4443 (metrics).
- Any future change pinning metrics-server to control planes can revisit and tighten these rules.
