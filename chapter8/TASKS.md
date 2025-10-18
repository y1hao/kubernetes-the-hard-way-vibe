# Chapter 8 Execution Plan — Cluster Networking (Calico)

## Prerequisites
1. Confirm `chapter5/kubeconfigs/admin.kubeconfig` works from the bastion using `chapter5/bin/kubectl`.
2. Ensure the pod CIDR (`10.200.0.0/16`) and service CIDR (`10.32.0.0/24`) values from earlier chapters remain unchanged.

## Execution Steps
1. Download the upstream Calico v3.28.2 manifest and store it as `chapter8/manifests/calico-upstream.yaml` for traceability.
2. Render `chapter8/calico.yaml` by applying cluster-specific edits (pod CIDR, encapsulation mode confirmation, IP autodetection hints) to the upstream manifest.
3. Add `chapter8/README.md` describing deployment commands, validation workflow, and NetworkPolicy guidance notes.
4. Create helper YAML under `chapter8/tests/` to launch two test pods and a ClusterIP service for connectivity checks.
5. Document a validation checklist covering Calico DaemonSet readiness, pod-to-pod ping, and service VIP curl commands.

## Validation Steps
1. `chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig get pods -n kube-system` shows all Calico components Available.
2. Test pods scheduled on different workers can ping each other successfully.
3. Curling the test service ClusterIP from either pod returns the expected response.
