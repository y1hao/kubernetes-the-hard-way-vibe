# Chapter 11 Execution Plan — RBAC, Security, and Policies

## Execution Steps
1. Create `chapter11/manifests/admin-clusterrolebinding.yaml` that binds the `admin` user to the `cluster-admin` ClusterRole.
2. Create `chapter11/manifests/default-deny-networkpolicy.yaml` that enforces default deny ingress and egress within the `default` namespace.
3. Create `chapter11/manifests/default-allow-from-ingress.yaml` that permits ingress into `default` workloads from namespaces labelled `networking.k8s.io/policy-role=ingress`.
4. Write `chapter11/README.md` covering manifest application steps, namespace labelling guidance, kubelet read-only port verification, and why existing security group rules remain in place.
5. Capture validation commands in `chapter11/README.md`, including RBAC checks with a non-admin kubeconfig and NetworkPolicy probe guidance for the operator to run from the bastion.
