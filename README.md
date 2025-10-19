# Kubernetes the Hard Way (Vibe Version)

## Motivation

Kubernetes the Hard Way is a classic learning resource for people who want learn Kubernetes seriously. I also followed it when I first learned Kubernetes a couple of years ago. It did give me more familarity and a better mental model of the moving pieces in Kubernetes. However, since the explanations in that tutorial were very brief, for many parts I ended up just following along by copying and pasting the documented bash snippets, without really gaining a thorough understanding. In the end, everything worked, but I still didn't feel 100% confident.

And I realised that's very similar to the experience of vibe coding. So I began to wonder - why don't I just vibe code the whole thing from scratch? In the end, I should get something that works as well, but in the process, I would get to make a lot more decisions, and ask a lot more questions - this should teach me more.

## Approach

The start of everything is this prompt to ChatGPT 5:

```
There is a popular learning resource in the k8s community - kubernetes the hard way, which shows how to bootstrap a cluster in cloud without using a managed offering or out-of-the-box bootstrapper. Now, I want to do something similar, however, instead of following that tutorial, I want to do it by chatting with you. 

Our goals are: 
- Create a kubernetes cluster on AWS 
- We aim to use the minimal offerings from AWS like EC2 and VPCs. We don't use EKS 
- We don't use things like kubeadm. Instead, we manually install everything from source by hand 
- We need to make sure all control plane components are configured correctly so they can talk with each other. This will include certificates are generated and distributed correctly 
- We want to have 3 control plane nodes and 2 worker nodes 
- In the end, we need to be able to create a simple service (nginx is fine) running as a Deployment which we can reach to from the internet 

Doing everything at once is hard. So, let's first start with a high level overview. Please arrange all the things we need to do into several relatively self-contained "chapters". We'll then dig into each "chapter" to get things working gradually.
```

From there, ChatGPT created a detailed roadmap, which I saved in [SPEC.md](./spec.md). As part of Chapter 0, I also got a detailed project architecture doc which I saved in [ARCHITECTURE.md](./ARCHITECTURE.md).

For each chapter, I used Codex to discuss, plan and execute. After each chapter is done, I asked Codex to generate a summary of what was completed in the chapter below:

## Summaries for each completed chapter

### Chapter 0

- Documented the target AWS-based Kubernetes architecture with decisions and rationale in `ARCHITECTURE.md`.
- Appended an ASCII topology diagram illustrating VPC, AZ, subnet, and node placement.
- Clarified Calico’s VXLAN mode and its alternatives, plus explained kube-proxy’s IPVS mode behavior.

### Chapter 1

- Captured Chapter 1 prerequisite decisions in `ADRs/000-chapter1-network-prep-decisions.md` and indexed them via `DECISIONS.md`.
- Scaffolded `chapter1/terraform/` with network and security modules, plus documented inputs and notes for future chapters.
- Provisioned the AWS network substrate (VPC, subnets, IGW, managed NAT, security groups) using Terraform 1.13.3.

### Chapter 2

- Recorded Chapter 2 provisioning choices in `ADRs/001-chapter2-node-provisioning-decisions.md` and later right-sized the worker fleet via `ADRs/002-chapter2-worker-sizing-adjustment.md`, updating `DECISIONS.md` accordingly.
- Built `chapter2/terraform/` to launch 3× control-plane `t3.medium` instances and 2× worker `t3.small` instances with 20 GiB gp3 roots using cloud-init templates and dynamic Ubuntu 22.04 AMI discovery via SSM.
- Added committed ops assets: role-specific cloud-init (`chapter2/cloud-init/`), a static inventory (`chapter2/inventory.yaml`), and a bastion-run validation script (`chapter2/scripts/validate_nodes.sh`).

### Chapter 3

- Logged PKI strategy in `ADRs/003-chapter3-pki-decisions.md` and expanded `.gitignore` to keep generated secrets out of version control.
- Produced full PKI inventory under `chapter3/pki/` using `cfssl`, including apiserver, component, admin, and per-node kubelet certificates with documented SAN coverage.
- Generated secrets encryption material in `chapter3/encryption/`, drafted distribution/rotation guidance (`chapter3/pki/manifest.yaml`, `chapter3/REVOCATION.md`), and captured execution notes in `chapter3/README.md`.

### Chapter 4

- Brought up the three-node etcd cluster (v3.5.12) with TLS on all control-plane nodes using the Chapter 3 CA and staged binaries under `chapter4/bin/`.
- Extended the manifest-driven distribution tooling and added `chapter4/scripts/bootstrap_etcd_node.sh` to standardise service bring-up.
- Documented validation flows (`etcdctl endpoint status/health`, `member list`) and captured implementation notes in `chapter4/README.md`.

### Chapter 5

- Finalised control-plane assets under `chapter5/`, including env files, systemd units, distribution manifest, and an idempotent bootstrap script aligned with ADR 005.
- Removed the obsolete `--cloud-provider=none` flag, converted controller-manager/scheduler units to `Type=exec`, and fixed kube-apiserver advertising/permissions to eliminate handler timeouts.
- From the bastion ran `distribute_control_plane.sh --nodes <cp>` followed by `bootstrap_control_plane.sh` on each control-plane node (cp-a/b/c), confirmed services via `systemctl status`, and verified `/healthz?verbose`.

### Chapter 6

- Introduced the internal AWS NLB (`kthw-api-nlb`) with TCP 6443 listener and target group covering `cp-a`, `cp-b`, and `cp-c`, plus a private Route53 zone `kthw.lab` exposing `api.kthw.lab`.
- Stood up the dedicated `chapter6/terraform/` stack and README detailing usage, validation, and outputs for the shared API endpoint.
- Expanded Chapter 1 security groups so the control plane accepts kube-apiserver traffic from the NLB subnets, enabling load-balanced access from the bastion and future clients.

### Chapter 7

- Logged worker runtime decisions in `ADRs/007-chapter7-worker-stack-decisions.md` and updated `DECISIONS.md` to track Chapter 7 scope.
- Staged Kubernetes v1.31.1 worker binaries plus containerd v1.7.14/runc v1.1.12/crictl v1.31.1 under `chapter7/bin/`, templated configs in `chapter7/config/`, and defined distribution targets via `chapter7/manifest.yaml`.
- Authored `chapter7/scripts/enable_workers.sh` and README guidance so workers install the stack, register with the control plane, and remain `NotReady` pending the Chapter 8 CNI rollout.

### Chapter 8

- Captured Calico networking choices in `ADRs/008-chapter8-networking-decisions.md` and linked them through `DECISIONS.md`, then rendered a VXLAN-tuned manifest at `chapter8/calico.yaml` alongside the archived upstream source.
- Hardened networking prerequisites by expanding security group rules in `chapter1/terraform/modules/security/main.tf` for BGP/VXLAN traffic and documenting the dependency in `chapter8/README.md`.
- Added operational artifacts: `chapter8/README.md`, `chapter8/VALIDATION.md`, test fixtures in `chapter8/tests/connectivity.yaml`, and a kubelet proxy RBAC binding under `chapter8/manifests/kube-apiserver-to-kubelet-crb.yaml`.
- Authored `chapter5/scripts/update_hosts_entries.sh` to align `/etc/hosts` across bastion and nodes, enabling `kubectl exec` validation, and trimmed service-DNS tests until Chapter 9 delivers CoreDNS.

### Chapter 9

- Logged CoreDNS/Metrics Server decisions in `ADRs/009-chapter9-core-addons-decisions.md`, populated manifests under `chapter9/manifests/`, and scripted the request-header ConfigMap refresh via `chapter9/scripts/ensure_requestheader_configmap.sh`.
- Generated the front-proxy CA/client certs, distributed them with the Chapter 5 manifest, and updated `kube-apiserver.env` to include `--enable-aggregator-routing=true` so aggregated APIs accept proxied requests.
- Rolled out CoreDNS and a hostNetworked metrics-server deployment, refreshed `extension-apiserver-authentication`, and validated the aggregation layer (`k get apiservice v1beta1.metrics.k8s.io`, `k top nodes`).

### Chapter 10

- Captured ALB-focused exposure decisions in `ADRs/012-chapter10-app-exposure-decisions.md` and staged Terraform under `chapter10/terraform/` to provision the public ALB, security groups, target group, and instance attachments.
- Rendered nginx Deployment/Service manifests in `chapter10/manifests/` that surface node identity via Downward API variables, plus documented rollout/cleanup in `chapter10/README.md`.
- Applied the stack and workload from the bastion, then validated internet reachability by curling the ALB DNS name and confirming target health for both workers.

### Chapter 11

- Logged hardening choices in `ADRs/013-chapter11-security-decisions.md` and `ADRs/014-metrics-server-worker-placement.md`, covering RBAC, NetworkPolicies, and metrics-server worker placement.
- Added `chapter11/manifests/` RBAC + policy assets, refreshed metrics-server secrets/script, and confirmed hostNetwork metrics-server runs cleanly on workers with the aggregated API reachable.
- Documented validation steps in `chapter11/README.md` and `chapter11/VALIDATION.md`, including kubelet read-only checks and guidance for ingress namespace labelling.

### Chapter 12

- Captured a documentation-only scope for resiliency work in `ADRs/015-chapter12-backup-upgrade-dr-deferral.md`, deferring automation until the resiliency milestone is staffed.
- Outlined etcd snapshot automation, control-plane upgrade, and node replacement workstreams with proposed scripts and docs in `chapter12/README.md`.
- Listed validation drills, ownership prerequisites, and follow-up decisions to unblock future execution of the Chapter 12 plan.
