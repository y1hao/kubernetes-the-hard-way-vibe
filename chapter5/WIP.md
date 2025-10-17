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
- ✅ Resolved: API server handler timeouts and the controller-manager crash loop were fixed by correcting systemd unit types, removing the deprecated `--cloud-provider=none` flag, and rerunning the bootstrap workflow to reset file ownership.
- ✅ Resolved: cp-b and cp-c have been bootstrapped with the same distribution + user creation steps; all three control planes report healthy services and `/healthz?verbose`.
- ✅ Resolved: Chapter 5 validation commands have been captured in `chapter5/README.md`.

> **Note:** This WIP log is now frozen for posterity. The outstanding items listed here have been addressed, and future tweaks should be tracked through new entries or commit logs instead of updating this section.
