# ADR: Chapter 11 Security & Policy Decisions

## Status
Accepted

## Context
Chapters 0–10 delivered a functional Kubernetes control plane, workers, networking, and public app exposure. Chapter 11 focuses on hardening the baseline: reinforcing RBAC, guarding kubelet access, introducing foundational NetworkPolicies, and double-checking security group posture without breaking observability components such as Metrics Server. The SPEC calls for an explicit admin binding, kubelet read-only protection, security group tightening, and baseline denial policies while keeping the cluster operational.

## Decision
- **RBAC baseline**: Create an explicit ClusterRoleBinding that maps the Chapter 3 `admin` client certificate user to the built-in `cluster-admin` ClusterRole. This codifies admin access rather than relying solely on implicit `system:masters` behavior.
- **Namespace policies**: Ship namespace-scoped NetworkPolicies that (a) apply a default deny on ingress and egress within the `default` namespace, and (b) allow traffic only from namespaces labelled `networking.k8s.io/policy-role=ingress` to workloads that opt in. This offers an extendable pattern for future namespaces while leaving kube-system untouched.
- **Metrics Server posture**: Retain the existing hostNetwork Metrics Server deployment so it can run on either control-plane or worker nodes. Preserve the security group rules that permit kube-apiserver-to-metrics (TCP/4443) and metrics-to-kubelet (TCP/10250) flows across node roles; document their necessity instead of removing them.
- **Kubelet hardening**: Keep the kubelet read-only port disabled (already set to 0 in kubelet configs) and document verification steps. No new kubelet exposures will be opened.
- **Artifact layout**: Place RBAC and NetworkPolicy manifests under `chapter11/manifests/`, with validation/usage guidance in `chapter11/README.md` to align with previous chapters.

## Consequences
- Admin access is now auditable via a manifest rather than implicit CA group membership, aiding future reviews or automation.
- Default-deny policies may require namespace owners to craft explicit allows; shipping an example ingress namespace lowers the barrier while keeping the default application namespace locked down.
- Leaving Metrics Server eligible to run on all nodes keeps topology flexible but obligates us to maintain the broader security group allowances; future specialization would be required to trim them further.
- With the kubelet read-only port disabled and RBAC tightened, unauthenticated kubelet access remains blocked. Operational runbooks must rely on the authenticated 10250 endpoint.
- The new manifests and docs provide a consistent starting point for future policy iterations without reworking earlier chapters.

## Follow-up
- Implement the manifests and documentation outlined above.
- Review security group rules periodically; if Metrics Server is later pinned to specific nodes, revisit the ingress reductions.
- Consider extending default-deny coverage to additional namespaces (e.g., `ingress`) once workloads are categorized.
