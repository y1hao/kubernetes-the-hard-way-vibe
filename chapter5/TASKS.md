# Chapter 5 Execution Plan — Kubernetes Control Plane

## Prerequisites
1. Confirm the Chapter 3 PKI artifacts (component certs, encryption config, admin kubeconfig materials) are present on the bastion and match ADR 005 expectations.
2. Verify etcd v3.5.12 is healthy on `cp-a`, `cp-b`, and `cp-c` via `etcdctl endpoint health`.
3. Ensure the bastion can SSH to all control plane nodes with privilege escalation (sudo) available.

## Execution Steps
1. **Stage Kubernetes v1.31.1 binaries**
   - Download the upstream Kubernetes v1.31.1 server tarball to `chapter5/artifacts/`.
   - Extract `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, and `kubectl`; place copies in `chapter5/bin/` for distribution.
2. **Prepare kubeconfigs and supporting files**
   - Use Chapter 3 certs to craft `kube-controller-manager.kubeconfig`, `kube-scheduler.kubeconfig`, and `admin.kubeconfig` targeting the control plane NLB endpoint.
   - Store these under `chapter5/kubeconfigs/` with documented generation commands.
3. **Author configuration and systemd assets**
   - Create environment/configuration files for each component under `chapter5/config/<component>/` reflecting ADR 005 flags and directories.
   - Write systemd unit files `kube-apiserver.service`, `kube-controller-manager.service`, and `kube-scheduler.service` enforcing the dedicated system users and dependencies.
4. **Define distribution manifest and helper scripts**
   - Extend or supplement the existing distribution tooling so Chapter 5 assets can be pushed according to a new `chapter5/manifest.yaml` covering binaries, configs, kubeconfigs, and kubectl destinations (including the bastion copy).
   - Provide a bootstrap script to create system users, adjust permissions, reload systemd, and start services on each control plane node.
5. **Distribute and bootstrap on cp-a**
   - Run the distribution workflow for `cp-a`, execute the bootstrap script, and verify services start cleanly (`systemctl status` for each component).
6. **Repeat rollout for cp-b and cp-c**
   - Perform the same distribution and bootstrap steps on `cp-b` and `cp-c`, confirming all components are active and pointing at the shared etcd cluster.
7. **Validate control plane health**
   - From a control plane node, run `kubectl --kubeconfig /var/lib/kubernetes/admin.kubeconfig get componentstatuses` (or equivalent health endpoints) to confirm API server, controller-manager, and scheduler report healthy.
   - Confirm leader election entries appear in controller-manager and scheduler logs.
8. **Document outcomes**
   - Update `chapter5/README.md` with implementation notes, execution commands, and validation results.
   - Record Chapter 5 summary in the top-level `README.md` after final confirmation.

## Validation Steps
1. `systemctl is-active kube-apiserver`, `kube-controller-manager`, and `kube-scheduler` return `active` on all control plane nodes.
2. `kubectl --kubeconfig /var/lib/kubernetes/admin.kubeconfig get --raw='/healthz?verbose'` returns `ok` with subchecks passing.
3. Controller-manager and scheduler logs on at least one node show successful leader election.
4. The bastion’s `kubectl` binary reports the cluster version when running `kubectl version --kubeconfig chapter5/kubeconfigs/admin.kubeconfig`.
