# Chapter 12 — Backups, Upgrades, and DR

This note outlines how we would tackle the Chapter 12 resiliency tasks without executing them yet. Everything below can be carried out from the bastion host against the existing control plane.

## Workstreams we would execute

### etcd snapshot automation
- Confirm `etcdctl` availability on the bastion (`etcdctl version`) and export `ETCDCTL_API=3`.
- Discover the current endpoints (`ETCDCTL_ENDPOINTS=https://127.0.0.1:2379` on each control plane, or use the LB hostname) and ensure the bastion has the matching client certs/keys.
- Author daily cron-friendly scripts:
  - `etcdctl snapshot save /var/backups/etcd/$(date +%F).db`.
  - Upload each snapshot to durable storage (e.g., `aws s3 cp` or `gsutil cp`).
- Provide a restore helper that copies the snapshot locally and runs `etcdctl snapshot restore` with the correct initial cluster flags for a single control-plane member.
- Document retention (30 days) and on-call rotation responsible for verifying the off-site copy succeeds.

### Control-plane rolling upgrade procedure
- Capture the current Kubernetes and etcd versions (`kubectl version --short`, `etcdctl version`).
- Produce a version compatibility matrix (control plane ↔ kubelet) from the official documentation.
- For each control-plane node:
  1. Cordon and drain workloads that landed there inadvertently (`kubectl drain <cp-node> --ignore-daemonsets --delete-emptydir-data`).
  2. Stop kube-apiserver, kube-controller-manager, kube-scheduler, and kubelet services.
  3. Upgrade binaries and systemd unit files (download from the release tarballs, verify checksums).
  4. Restart services in dependency order, watch logs, then run health checks (`kubectl get componentstatuses`, `/livez`, `/readyz`).
  5. Uncordon once healthy.
- Note that etcd upgrades ride along only after control-plane binaries succeed; include rollback notes if health checks fail.

### Node replacement runbook
- Prepare an AMI/instance template matching current workers (container runtime, kubelet version, CNI bits).
- Document how to rotate an instance:
  1. `kubectl cordon <node>` and `kubectl drain <node> --ignore-daemonsets`.
  2. In EC2, terminate or stop the instance and tag it for replacement.
  3. Provision a new node (autoscaling group or Terraform apply) with the same labels/taints.
  4. Join it with `kubeadm join` (or the custom bootstrap script used earlier); verify it registers in `kubectl get nodes`.
  5. Uncordon once workloads resettle.
- Keep a “break glass” checklist for simultaneous multi-node failures (prioritise etcd quorum, then restore workers).

## Proposed artifacts
- `chapter12/scripts/etcd-snapshot-save.sh` and `chapter12/scripts/etcd-snapshot-restore.sh` templates (to be implemented).
- `chapter12/docs/control-plane-upgrade.md` capturing the detailed rolling upgrade steps and version matrix references.
- `chapter12/docs/node-replacement-runbook.md` plus a high-severity incident checklist.

## Validation we would perform
- In a disposable environment, run the snapshot script, nuke etcd data, and restore from the latest backup; confirm the API server recovers.
- For upgrades, rehearse on a single control-plane node clone or staging cluster and ensure the API stays available (check `kubectl get --raw=/livez`).
- During node rotation, watch workloads (`kubectl get pods -A -w`) to ensure they reschedule, and confirm no PDB violations or evicted system pods.
- After each exercise, review CloudWatch or Prometheus alerts to tune thresholds before production use.

## Next steps before execution
- Align on storage destination for snapshots (S3 bucket, lifecycle policy, encryption requirements).
- Decide who owns the cron infrastructure (systemd timer, Kubernetes CronJob, or external scheduler).
- Verify we have maintenance windows approved for control-plane and worker disruptions.
- Once the above decisions are settled, we can scaffold the scripts and docs under `chapter12/` and stage validation in a sandbox cluster.
