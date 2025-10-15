# ADR: Chapter 1 AWS Network Preparation Decisions

## Status
Accepted

## Context
We are moving from Chapter 0 (architecture and scope) into Chapter 1 of the project, where the focus shifts to standing up the AWS network substrate that will host the Kubernetes cluster. Before drafting the execution plan, we needed to lock in foundational parameters so Terraform modules, security posture, and documentation can be authored without open questions.

## Decision
- **AWS region**: Build the cluster in `ap-southeast-2` to keep latency low for NZ-based operators while retaining three mature availability zones.
- **Availability zone mapping**: Anchor node suffixes to deterministic ZoneIds — `cp-a`/`worker-a` → `apse2-az1` (`ap-southeast-2a`), `cp-b`/`worker-b` → `apse2-az2` (`ap-southeast-2c`), `cp-c`/`worker-c` (reserved) → `apse2-az3` (`ap-southeast-2b`).
- **CIDR layout**: Retain the Chapter 0 addressing plan: VPC `10.240.0.0/16`; public subnets `10.240.0.0/24`, `10.240.32.0/24`, `10.240.64.0/24`; private subnets `10.240.16.0/24`, `10.240.48.0/24`, `10.240.80.0/24`; pod CIDR `10.200.0.0/16`; service CIDR `10.32.0.0/24`.
- **Outbound internet strategy**: Provision a managed NAT gateway with an Elastic IP for the private subnets to minimise manual proxying during node bootstrap while keeping teardown predictable.
- **SSH access**: Generate a fresh local `ed25519` key pair (`kthw-lab`) and import the public key into AWS for bastion and node access (key creation deferred to implementation stage).
- **Tooling versions**: Use Terraform `1.13.3` as the pinned IaC version; rely on AWS CLI v2 (latest) and `jq` 1.6 for supporting automation.
- **Tagging & naming**: Apply `Project=K8sHardWay`, `Role={ControlPlane|Worker|Bastion|Network}`, and `Env=Lab` to AWS resources; keep node names `cp-{a,b,c}` and `worker-{a,b,c}` aligned with the AZ mapping.
- **Documentation artifacts**: Capture these constants in `chapter1/inputs.md` (to be authored during implementation) and reflect them inside Terraform variable defaults and comments for cross-chapter reuse.

## Consequences
- Terraform modules for Chapter 1 can be scaffolded immediately with definitive region, subnet, and routing parameters.
- Managed NAT costs are incurred, but network bootstrap is simpler and closer to real-world workflows.
- Future chapters can rely on a consistent AZ-to-suffix mapping and tagging scheme, reducing ambiguity in provisioning scripts and documentation.
- SSH key management remains under operator control without committing private material to the repository.

## Follow-up
- Generate and register the `kthw-lab` SSH key before provisioning the bastion (Chapter 1 execution).
- Author `chapter1/inputs.md` summarising these decisions alongside Terraform variable definitions when implementation begins.
- Document NAT gateway teardown guidance in Chapter 1 notes to manage ongoing costs.
