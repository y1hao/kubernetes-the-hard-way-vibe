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
