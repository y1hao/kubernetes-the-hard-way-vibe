Here are the roadmap of this project:

# Chapter 0 — Scope, topology & prerequisites

**Decisions**

* 3 control planes + 2 workers, spread across 3 AZs (control plane across all AZs, workers in AZ a and AZ b).
* Minimal AWS: VPC + subnets + EC2 + (option A) NLBs for stable L4 only (recommended), or (option B) a self-managed HA pair with EIP failover for purists.
* Linux distro: Ubuntu LTS or Flatcar (pick one and stick to it).
* Container runtime: `containerd`.
* CNI: Calico (simple, self-contained; no AWS-CNI/IAM plumbing).
* PKI: OpenSSL or `cfssl` (single cluster CA you control).
* Service CIDR and Pod CIDR (non-overlapping with VPC).

**Artifacts**

* Architecture doc: IP plan, CIDRs, DNS names, ports.
* Jump/bastion host plan (or SSM Session Manager).
* Tooling: `awscli`, `jq`, `kubectl`, `etcdctl`, `cfssl`/OpenSSL.

**Validation**

* Everyone agrees on CIDRs, AZ spread, naming, and the exposure strategy (NLB vs self-managed HA).

---

# Chapter 1 — AWS network substrate

**Work**

* Create VPC (e.g., `10.24.0.0/16`).
* 3 public subnets (one per AZ) for load balancers/bastion; 3 private subnets for nodes.
* IGW, NAT (if needed), route tables, NACLs (keep simple), security groups (principle of least privilege; open only what we must).
* Key pairs & instance profiles (minimal/no IAM if we avoid AWS-CNI; SSM optional).

**Artifacts**

* Terraform (or shell) that can destroy/recreate the VPC.
* Security group rules list (documented).

**Validation**

* From bastion: ping/ssh to all planned nodes; outbound internet works for package fetch.

---

# Chapter 2 — Provision the 5 EC2 nodes

**Work**

* Launch 3× control-plane EC2 on `t3.medium` and 2× worker EC2 on `t3.small`, each with 20 GiB gp3 root volumes via Terraform (`chapter2/terraform/`).
* Source the Ubuntu 22.04 LTS AMI dynamically by scanning the SSM path `/aws/service/canonical/ubuntu/server/22.04/stable` and selecting the latest `amd64/hvm/ebs-gp2/ami-id`, avoiding hand-curated AMI IDs.
* Attach deterministic private IPs per ADR 002 (`cp-a 10.240.16.10`, …, `worker-b 10.240.48.20`) and reuse Chapter 1 security groups and private subnets through remote state. Reserve `10.240.80.20` for future expansion.
* Apply base hardening with role-specific cloud-init (`chapter2/cloud-init/`) that sets hostnames, disables swap, loads `overlay`/`br_netfilter`/`nf_conntrack`, enforces Kubernetes sysctls, upgrades packages, and installs baseline tooling (`chrony`, `conntrack`, `socat`, `iptables`, `nfs-common`, `curl`, `jq`).

**Artifacts**

* Terraform root at `chapter2/terraform/` with static node definitions and outputs for node metadata, control planes, and workers.
* Cloud-init templates: `chapter2/cloud-init/control-plane.yaml` and `chapter2/cloud-init/worker.yaml`.
* Inventory file `chapter2/inventory.yaml` plus validation helper `chapter2/scripts/validate_nodes.sh` (expects PyYAML on the bastion).

**Validation**

* From the bastion: `ssh` to each node succeeds; `chapter2/scripts/validate_nodes.sh` reports swap disabled, kernel modules present, and required sysctls set.

---

# Chapter 3 — Build the PKI

**Work**

* Generate a root CA and intermediate (optional).
* Issue certs/keys for:

  * kube-apiserver (with SANs: individual CP node IPs, the API LB DNS name, `kubernetes`, `kubernetes.default`, service IP).
  * kube-controller-manager, kube-scheduler.
  * kubelet (one per node; CN = `system:node:<nodeName>`, O = `system:nodes`), or enable TLS bootstrap later.
  * kube-proxy.
  * admin user (CN = `admin`, O = `system:masters`).
* Generate encryption-config for secrets at rest.

**Artifacts**

* CA material + certs/keys neatly organized, with a distribution manifest.
* Revocation & rotation plan (notes).

**Validation**

* `openssl verify`/`cfssl certinfo` on all certs; SANs cover every endpoint we’ll use.

---

# Chapter 4 — etcd cluster (3 nodes on control planes)

**Work**

* Install `etcd` binaries (from upstream releases or built from source).
* Create systemd units with peer URLs, client URLs, and TLS everywhere.
* Data dir on separate volume (optional).

**Artifacts**

* `/etc/etcd/*` configs, systemd unit files.
* etcdctl wrapper env file for TLS flags.

**Validation**

* `etcdctl endpoint status/health` from each CP node (and from bastion through the LB or direct if allowed).
* Member list shows 3 voters, healthy.

---

# Chapter 5 — Kubernetes control plane components

**Work**

* Install from upstream tarballs/source: `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, `kubectl`.
* Configure:

  * **kube-apiserver**: point to etcd (TLS), enable RBAC, admission plugins, secure/metrics ports, service CIDR, pod CIDR range (for controller), encryption-config, audit policy (optional).
  * **kube-controller-manager**: cluster-CIDR (for CNI), service-CIDR, node CIDR allocation, cloud-provider **none**.
  * **kube-scheduler**: use default profiles, secure port + TLS.
* Systemd units and dedicated Linux users.

**Artifacts**

* `/etc/kubernetes/manifests` or `/etc/kubernetes/*.yaml` (we’ll use systemd, not static pods).
* kubeconfigs for controller-manager and scheduler (client certs).

**Validation**

* All three CP nodes have running apiserver/CM/scheduler.
* From a CP node: `kubectl --kubeconfig /…/admin.kubeconfig get componentstatuses` (or probe metrics/healthz endpoints).
* Leader election observed in logs.

---

# Chapter 6 — Stable API access (front the apiserver)

**Option A (recommended, simple): AWS NLB**

* Create an **internal** NLB spanning the 3 private subnets.
* Target group: the three kube-apiserver ports (`:6443`) on each CP node (TCP).
* Health checks on `/livez` with TLS proxy or just TCP 6443.
* Create a private Route53 record `api.<cluster>.internal` → NLB.

**Option B (self-managed)**

* A pair of HAProxy nodes in public subnets; a tiny failover script to reassign an Elastic IP on failure (since VRRP VIPs don’t float in VPC L2). More moving parts; we can outline later.

**Artifacts**

* The chosen front-door and a single canonical **API DNS name**.
* `admin.kubeconfig` pointing at that DNS name (SAN must match).

**Validation**

* From bastion: `kubectl --kubeconfig admin.kubeconfig get ns` works through the front door.
* Kill one apiserver; requests still succeed via the LB.

---

# Chapter 7 — Worker node stack

**Work**

* Install `containerd`, `runc`, `crictl`.
* Install `kubelet` and `kube-proxy` binaries.
* Configure `containerd` (systemd cgroups, registries if needed).
* Provide each worker a `kubelet.kubeconfig` (or enable TLS bootstrap with a bootstrap token).
* Kubelet flags: cluster DNS (once CoreDNS is up), cluster domain, node IP, rotate certs (optional).
* Kube-proxy: iptables mode (simple), kubeconfig.

**Artifacts**

* `/etc/containerd/config.toml`, kubelet & kube-proxy systemd units, kubeconfigs.
* Per-node certs if not using TLS bootstrap.

**Validation**

* `systemctl status` clean; `kubectl get nodes` shows both workers **Ready** (CNI pending until next chapter).

---

# Chapter 8 — Cluster networking (CNI)

**Work**

* Deploy **Calico** (manifests tuned to your Pod CIDR). No cloud provider required; use VXLAN (or IP-in-IP).
* Confirm kube-proxy rules present; MTU set sanely (AWS ENA typically 9001—Calico default auto-detect).

**Artifacts**

* Rendered Calico YAML with your CIDRs/MTU.
* Notes on NetworkPolicy examples.

**Validation**

* `kubectl get pods -n kube-system` shows Calico DaemonSets ready.
* Launch 2 test pods on different nodes, `ping` works across pods, `kubectl exec` curl service VIPs works.

---

# Chapter 9 — Core add-ons

**Work**

* **CoreDNS** (upstream manifest), **Metrics Server** (optional), cluster roles for admins.
* Configure cluster DNS IP (usually first IP of service CIDR).

**Artifacts**

* Add-on manifests with your service CIDR/DNS.
* A small “cluster-info” README.

**Validation**

* `nslookup kubernetes.default` from a pod resolves.
* `kubectl top nodes` works if Metrics Server installed.

---

# Chapter 10 — App exposure to the internet

**Option A (with NLB, simple & robust)**

* Deploy a **public** NLB in the public subnets.
* Target group = worker nodes on a chosen **NodePort** (e.g., 30080).
* Create a Service for nginx `type: NodePort` on that port.
* Optional: introduce an Ingress Controller later; for now, direct L4 works.

**Option B (self-managed)**

* Put a tiny HAProxy/NGINX reverse proxy VM in a public subnet; forward `:80/:443` to NodePort on worker nodes (with simple health checks).

**Artifacts**

* NLB and Route53 (or raw public IP) published as `app.<yourdomain>`.
* Nginx Deployment + Service YAML.

**Validation**

* From the internet: `curl http://app.<yourdomain>` returns nginx welcome page.
* Kill one worker; traffic still flows (LB health checks OK).

---

# Chapter 11 — RBAC, security, and policies

**Work**

* Create an `admin` ClusterRoleBinding (system:masters already maps, but make it explicit).
* Lock down kubelet read-only port (disable), protect metrics ports, restrict security groups to needed ports only.
* Enable basic NetworkPolicies; deny-all + allow-from-ingress namespace examples.
* Secrets at rest already enabled (confirm).

**Artifacts**

* RBAC manifests, baseline NetworkPolicies, security group diff (tightened).

**Validation**

* Attempt forbidden actions with a non-admin kubeconfig; confirm denied.
* Netpol probes behave as intended.

---

# Chapter 12 — Backups, upgrades, and DR

**Work**

* etcd snapshots (cron + off-box copy).
* Document control-plane rolling upgrade procedure (one node at a time).
* Node replacement runbook.

**Artifacts**

* `etcdctl snapshot save/restore` scripts.
* Version matrix doc (kubelet vs control-plane compatibility).
* “Break glass” checklist.

**Validation**

* Perform a test etcd snapshot/restore in a disposable environment.
* Drain/uncordon a worker and verify workloads resettle.

---

# Chapter 13 — Public API exposure

**Work**

* Add a public NLB (or HA pair) that targets the control planes on `:6443` with cross-zone enabled.
* Tighten security groups and Route53 so only approved CIDRs reach `api.<cluster>.<domain>`.
* Regenerate kube-apiserver cert SANs and update `admin.kubeconfig` to point at the public host.
* Layer optional protections: AWS WAF, CloudWatch alarms, audit log reviews.

**Artifacts**

* IaC for the public NLB + security group.
* CIDR allowlist doc and rotation SOP.
* Updated kubeconfigs plus remote access runbook.

**Validation**

* `kubectl --kubeconfig admin-public.kubeconfig get --raw=/livez` succeeds from the internet.
* Removing your CIDR from the security group blocks access.
* Killing one control plane node keeps the API reachable via the NLB.

---

# Chapter 14 — Cleanup

**Work**

* Keep an inventory of EC2, volumes, DNS, and LBs tagged for the cluster.
* Revise and document the live cluster topology, control plane/worker roles, front doors, and dependencies before teardown.
* Ship guarded teardown tooling (`cleanup.sh`, Terraform destroy) with confirmations.
* Take final etcd snapshots and back up AMIs/S3 before destroying anything.

**Artifacts**

* `cleanup.sh`/Terraform destroy plan with tag filters.
* Final-state architecture notes (diagram + narrative) covering nodes, networking, and access paths.
* Manual checklist for log retention, WAF, leftovers.

**Validation**

* Dry-run cleanup in staging and confirm no orphaned resources remain.
* Recreate the cluster from backups to prove recoverability.
