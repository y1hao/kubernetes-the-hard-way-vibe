# Kubernetes the Hard Way — Target Architecture

This document captures the desired end-state architecture for the cluster we are about to build by hand on AWS. It explains the topology, core components, access patterns, and key design decisions together with the reasoning behind each choice. The goal is to ensure every decision is explicit and reviewed before any infrastructure is provisioned.

## Cluster Topology & Availability

- **Nodes**: 3 control plane nodes and 2 worker nodes.
  - Control plane maintains quorum even if one AZ or instance is lost.
  - Worker capacity lives in AZ a and AZ b for cost savings; AZ c hosts only a control plane node until we scale out.
- **Availability Zones**: Spread the control plane across all three AZs; keep workers in AZ a and AZ b while leaving the AZ c worker slot idle for now.
  - Avoids multi-region latency while preserving control plane resilience; note that losing AZ a or AZ b removes worker capacity until we scale out again.
  - Aligns with AWS fault domains and keeps costs predictable.
- **Instance Sizing**: Control plane nodes run on `t3.medium`; workers run on `t3.small` to trim unused capacity.
  - Keeps etcd and control components responsive while cutting worker costs; monitor aggregate pod memory when scheduling demos.
  - Leaves headroom for control plane workloads (etcd + Kubernetes components) and basic application demos.

## Network Layout

- **VPC CIDR**: `10.240.0.0/16` dedicated to this environment.
  - Large enough to carve subnets for control planes, workers, and public access while staying isolated from common corporate ranges.
- **Subnets**: For each AZ, create one public subnet (for bastion/LBs) and one private subnet (for nodes).
  - Public subnets expose only the bastion and load balancers; worker and control plane nodes remain private.
  - Simplifies routing by aligning subnets with AZs and supports static private IP assignment per node.
- **Routing**: Internet Gateway attached to the VPC. NAT gateway is optional; outbound traffic from private subnets can be proxied through the bastion when necessary.
  - Minimizes AWS dependencies while preserving the ability to fetch packages during bootstrap.

## Kubernetes Networking Choices

- **Pod CIDR**: `10.200.0.0/16` assigned cluster-wide.
  - Provides ample address space and avoids overlap with the VPC and Service CIDR.
- **Service CIDR**: `10.32.0.0/24`.
  - Keeps service IP range compact and easy to reason about, while leaving space for future expansion if required.
- **CNI Plugin**: Calico running in VXLAN mode.
  - Self-contained solution with mature NetworkPolicy support and no dependence on AWS IAM.
  - VXLAN keeps routing simple across subnets; MTU adjustments (target 8941) will be documented if necessary.
- **Kube-Proxy**: IPVS mode once the cluster is up.
  - More predictable performance under load compared to iptables, and Calico fully supports it.

## Control Plane Components

- **Runtime**: `containerd` deployed on every node.
  - Matches upstream Kubernetes defaults, avoids legacy Docker shim, and keeps the footprint minimal.
- **etcd**: Three-node etcd cluster colocated with the control plane nodes.
  - TLS secured peer and client traffic; data directories stored on dedicated volumes for easier backup.
- **Kubernetes Binaries**: `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, and `kubelet` installed directly from upstream release tarballs.
  - Preserves the spirit of “the hard way” by avoiding packaged installers like kubeadm.
  - Systemd units manage lifecycle with explicit flags captured in version-controlled manifests.

## Access & Tooling Strategy

- **Bastion Host**: Single Ubuntu 22.04 instance in a public subnet, limited inbound to known admin IPs.
  - Primary entry for SSH and node-level work while keeping the data plane private.
  - Doubles as the control point for certificate distribution and configuration management via `scp`/`ssh`.
- **Public API Access**: Approved operator networks reach the kube-apiserver through a public NLB with restricted CIDRs and Route53.
  - Enables direct `kubectl` from workstations without hopping through the bastion while preserving auditing and guardrails.
- **Optional SSM**: Evaluate AWS Systems Manager Session Manager as an enhancement.
  - Could eliminate public SSH altogether later, but bastion remains the baseline due to deterministic workflow.
- **Admin Tooling**: Install `awscli`, `jq`, `kubectl`, `cfssl`, `etcdctl`, and `helm` (for future add-ons) on both local machines and the bastion.
  - Ensures consistent operator experience; `cfssl` accelerates cert generation, `jq` aids AWS CLI parsing, and `kubectl` enables verification once the API is online.

## PKI & Security Posture

- **Certificate Authority**: Offline root CA with optional online intermediate used to issue component certificates.
  - Simplifies revocation and rotation while keeping the highest-privilege keys off AWS.
- **Certificates**: Individual cert/key pairs for kube-apiserver, etcd peers/clients, controller-manager, scheduler, kubelets, kube-proxy, and an admin user.
  - SANs include API server private IPs, the load balancer DNS name, and the default service names required by Kubernetes.
- **Secrets**: Encryption at rest configured via the API server using an encryption config managed through the bastion.
- **OS Hardening**: Ubuntu 22.04 chosen for its long-term support, predictable security updates, and familiar package management.
  - Base configuration disables swap, enforces `chrony` for time sync, and loads required kernel modules.

## External Exposure

- **Control Plane Endpoint (internal)**: AWS Network Load Balancer fronting the three control plane nodes on TCP 6443 inside the VPC.
  - Native health checks and cross-AZ failover with minimal additional maintenance.
  - Alternative (documented but not primary): self-managed HAProxy pair with Elastic IP failover.
- **Control Plane Endpoint (public)**: Second NLB in public subnets exposing TCP 6443 to allowlisted operator CIDRs.
  - Shares the same targets as the internal NLB while layering WAF/CloudWatch alarms for edge visibility.
- **Application Exposure**: NLB also used later for user workloads by pointing to worker node NodePorts (e.g., 30080 for nginx demo).
  - Provides a stable, public entry point without managing Ingress controllers initially.
- **DNS**: Route53 publishes internal and public records (e.g., `api.kthw.internal`, `api.kthw.example.com`) aligned with the respective load balancers.

## Naming & Tagging Conventions

- **Hostnames**: `cp-a`, `cp-b`, `cp-c` for control planes and `worker-a`, `worker-b` for workers (with `worker-c` reserved), aligning the suffix with the AZ letter.
- **Tags**: Apply `Project=K8sHardWay`, `Role=ControlPlane|Worker|Bastion`, and `Env=Lab` to all AWS resources.
  - Simplifies search, IAM policies, and cleanup scripts.

## Operational Considerations

- **Backups**: Plan for scheduled etcd snapshots stored off-box (S3 or secure local storage).
- **Logging & Monitoring**: Base OS logs retained locally; future chapters may integrate CloudWatch or open-source stack, but not required for initial bring-up.
- **Documentation**: Maintain runbooks for bastion bootstrap, certificate distribution, and node provisioning under version control.

This architecture will be refined only if validation in Chapter 0 uncovers conflicts (e.g., CIDR overlap with existing networks or AWS quota limits). Otherwise, it forms the blueprint for the subsequent implementation chapters.

## Architecture Diagram

```
+-----------------------------------------------------------------------+
| AWS VPC 10.240.0.0/16                                                 |
|                                                                       |
|  +-----------------+     +-----------------+     +-----------------+  |
|  | Availability    |     | Availability    |     | Availability    |  |
|  | Zone a          |     | Zone b          |     | Zone c          |  |
|  |                 |     |                 |     |                 |  |
|  |  +-----------+  |     |  +-----------+  |     |  +-----------+  |  |
|  |  | Public    |  |     |  | Public    |  |     |  | Public    |  |  |
|  |  | Subnet    |  |     |  | Subnet    |  |     |  | Subnet    |  |  |
|  |  | 10.240.0  |  |     |  | 10.240.32 |  |     |  | 10.240.64 |  |  |
|  |  |  /24      |  |     |  |  /24      |  |     |  |  /24      |  |  |
|  |  |           |  |     |  |           |  |     |  |           |  |  |
|  |  |  Bastion  |  |     |  |  (future) |  |     |  |  (future) |  |  |
|  |  |  Host     |  |     |  |  LB nodes |  |     |  |  LB nodes |  |  |
|  |  |  NLB      |<-+-----+->|  NLB      |<-+-----+->|  NLB      |  |  |
|  |  +-----------+  |     |  +-----------+  |     |  +-----------+  |  |
|  |  +-----------+  |     |  +-----------+  |     |  +-----------+  |  |
|  |  | Private   |  |     |  | Private   |  |     |  | Private   |  |  |
|  |  | Subnet    |  |     |  | Subnet    |  |     |  | Subnet    |  |  |
|  |  | 10.240.16 |  |     |  | 10.240.48 |  |     |  | 10.240.80 |  |  |
|  |  |  /24      |  |     |  |  /24      |  |     |  |  /24      |  |  |
|  |  |           |  |     |  |           |  |     |  |           |  |  |
|  |  |  cp-a     |  |     |  |  cp-b     |  |     |  |  cp-c     |  |  |
|  |  |  etcd     |  |     |  |  etcd     |  |     |  |  etcd     |  |  |
|  |  |  worker-a |  |     |  |  worker-b |  |     |  |  worker (res) |  |  |
|  |  |           |  |     |  |           |  |     |  |           |  |  |
|  |  +-----------+  |     |  +-----------+  |     |  +-----------+  |  |
|  +-----------------+     +-----------------+     +-----------------+  |
|                                                                       |
|  Control Plane NLB (TCP 6443) -> NodePort NLB (TCP 30080)             |
|  Bastion: SSH, tooling, certificate distribution                      |
|  Calico VXLAN overlay across private subnets                          |
+-----------------------------------------------------------------------+
```
