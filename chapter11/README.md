# Chapter 11 — RBAC, Security, and Policies

This chapter hardens the cluster’s baseline security posture by:

- codifying admin access with an explicit ClusterRoleBinding for the `admin` client certificate.
- enforcing default deny in the `default` namespace plus an opt-in NetworkPolicy for ingress-managed workloads.
- validating kubelet read-only settings and documenting why the existing metrics-server-related security group rules remain.

## Artifacts

- `chapter11/manifests/admin-clusterrolebinding.yaml`
- `chapter11/manifests/default-deny-networkpolicy.yaml`
- `chapter11/manifests/default-allow-from-ingress.yaml`

## Application Steps (bastion)

1. `kubectl apply -f chapter11/manifests/admin-clusterrolebinding.yaml`
2. `kubectl apply -f chapter11/manifests/default-deny-networkpolicy.yaml`
3. `kubectl apply -f chapter11/manifests/default-allow-from-ingress.yaml`
4. Label ingress namespaces when ready, e.g. `kubectl label namespace ingress-nginx networking.k8s.io/policy-role=ingress`.
5. Label workloads that should receive ingress: `kubectl label deployment my-app kthw.lab/allow-from-ingress=true`.

## Validation

- `kubectl top nodes` now succeeds with metrics-server pinned to workers.
- With a non-admin kubeconfig (metrics-server, kube-proxy, etc.), `kubectl auth can-i create pods` should return `no`.
- From an ingress-labeled namespace, traffic to labeled `default` pods succeeds; from other namespaces it is denied/timeout.
- On any node, `sudo ss -ltnp | grep 10255` produces no output; `curl http://<node>:10255/metrics` fails, confirming the read-only kubelet port stay disabled.
- Note: control-plane↔worker kubelet (10250) and control-plane→worker metrics (4443) security group rules remain to satisfy hostNetwork metrics-server until it’s limited to the control-plane nodes.

