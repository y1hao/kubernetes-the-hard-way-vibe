# Chapter 5 — Work In Progress Log

## Date: 2025-10-17

### Resolved Issues
- Corrected kube-apiserver configuration to source TLS assets and etcd CA from `/var/lib/kubernetes`, fixing repeated `permission denied` errors on certificate/key files.
- Updated `bootstrap_control_plane.sh` to normalise ownership/permissions, copy the etcd CA, template node IPs, and inject the `api.kthw.lab` mapping into `/etc/hosts` so subsequent runs are consistent.
- Added `--requestheader-client-ca-file=/var/lib/kubernetes/ca.pem` to the controller-manager and scheduler configs to silence the missing `requestheader-client-ca-file` warnings without relying on the extension-apiserver ConfigMap.
- Removed deprecated `--port` flag from the scheduler for Kubernetes v1.31 compatibility.

### Current Status (cp-a)
- `kube-scheduler.service` is running and has acquired its leader lease after config updates.
- `kube-apiserver.service` restarts successfully with the expected flags but still emits frequent `http: Handler timeout` errors when the controller-manager attempts to write events/leases.
- `kube-controller-manager.service` remains in a crash loop due to repeated API server request timeouts; the service restarts but exits with status 1 after failing to update the leader lease.
- etcd members respond to health checks, although occasional `transport is closing` warnings continue to appear in the etcd logs when the API server times out.

### Outstanding Work
- Diagnose and eliminate the remaining API server handler timeouts (likely related to intermittent etcd RPC closures) so controller-manager can maintain its leader lease.
- Once cp-a is stable, replay the refreshed bootstrap/distribution workflow on cp-b and cp-c and verify all three control-plane nodes converge cleanly.
- After services are stable on all nodes, run Chapter 5 validation commands (`healthz`, `componentstatuses`, etc.) and capture results for documentation.
