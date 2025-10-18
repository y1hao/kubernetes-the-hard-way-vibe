# ADR: Control Plane Node Agent Integration

## Status
Accepted

## Context
Originally the control-plane nodes (cp-a/b/c) were dedicated hosts running only the Kubernetes control-plane services (kube-apiserver, kube-controller-manager, kube-scheduler) and etcd. No kubelets, container runtime, or Calico agents ran there. Consequently, the control plane could not reach pod IPs or scrape kubelet metrics, which blocked aggregated APIs such as Metrics Server and prevented DaemonSets (Calico) from running on those nodes.

Chapter 9 introduced requirements for Metrics Server and other aggregated APIs that depend on kubelet/Calico functionality on the control plane:
- Metrics Server must scrape every kubelet, including those on the controllers.
- APIService proxying requires the controllers to participate in the pod network for ClusterIP reachability.
- Running Calico on the controllers ensures VXLAN routes exist for pod traffic.

## Decision
- Install containerd, kubelet, and kube-proxy on all control-plane nodes, mirroring the worker stack.
- Allow the Calico DaemonSet to schedule on cp-a/b/c so the control plane joins the pod network.
- Reuse pre-issued kubelet certificates (Chapter 3) and kube-proxy configs so the controllers register as nodes.
- Maintain taints/labels as needed to keep regular workloads off the control plane while still enabling kubelet functionality.

## Consequences
- Control-plane nodes now appear as regular nodes in `kubectl get nodes`; scheduling policies must ensure control-plane isolation (e.g., via taints).
- Additional binaries/configs are distributed via `chapter5/manifest.yaml`, and `bootstrap_control_plane.sh` now enables containerd/kubelet/kube-proxy.
- Calico VXLAN routes exist on cp-a/b/c, enabling ClusterIP reachability and kubelet scrapes for aggregated APIs.
- Slightly higher operational complexity on the controllers, but enables richer functionality without introducing dedicated helper nodes.

## Follow-up
- Apply taints/labels if we want to keep controllers unschedulable for general workloads.
- Monitor resource usage on cp-a/b/c since they now host kubelet and Calico alongside control-plane services.
- Update operational docs and bootstrap checklists to reflect the new agent stack on the control plane.
