# ADR: Metrics Server Worker Placement

## Status
Accepted

## Context
Before Chapter 11, the metrics-server Deployment ran on control-plane nodes by default. We wanted confidence that the hostNetwork deployment, security groups, and kubelet credentials would also succeed if the scheduler placed metrics-server on worker nodes. During the move, we hit two blockers:

1. The Deployment’s kubeconfig secret still carried the admin kubeconfig because the helper script inherited the environment `KUBECONFIG`, so the generated secret never reflected the metrics-server identity.
2. The APIService trusted the backend only because the apiserver skipped TLS verification; once metrics-server moved to workers and restarted, the aggregated API rejected the handshake until we addressed the certificate mismatch.

## Decision
- Pin the metrics-server Deployment to worker nodes with `node-role.kubernetes.io/worker` labels and ensure workers are labeled accordingly.
- Fix `chapter9/scripts/generate_metrics_server_secrets.sh` to use an explicit `KTHW_METRICS_SERVER_KUBECONFIG` variable so the generated secret always includes the `system:metrics-server` credentials with correct file paths.
- Regenerate and reapply the metrics-server secrets, restart the Deployment, and verify `kubectl top nodes` works with the pod running on workers.
- For now, set `insecureSkipTLSVerify: true` on the APIService so the aggregator accepts the metrics-server self-signed serving cert when reached through hostNetwork.

## Consequences
- Metrics-server can freely land on worker nodes without breaking metrics, validating the SG pathways we intend to keep.
- The secrets generation script is safer—changing your shell `KUBECONFIG` no longer pollutes the generated manifest.
- We still rely on `insecureSkipTLSVerify` for the aggregated API; properly populating `spec.caBundle` remains future work if we want to remove that exception.
- HostNetwork plus worker placement keeps the existing security-group allowances (control-plane↔worker 10250 and control-plane→worker 4443) necessary; a future decision could pin metrics-server back to control planes and tighten rules.

## Follow-up
- Consider issuing a dedicated metrics-server serving certificate and wiring `spec.caBundle` so we can disable `insecureSkipTLSVerify`.
- Document the worker labeling requirement in the operational runbooks to avoid unscheduled pods during node replacements.
- Revisit security group tightening once metrics-server deployment topology is finalised.
