# Chapter 1 Inputs & Constants

## AWS Region & Availability Zones
- Region: `ap-southeast-2`
- AZ suffix mapping:
  - `a` → ZoneId `apse2-az1` (`ap-southeast-2a`)
  - `b` → ZoneId `apse2-az2` (`ap-southeast-2c`)
  - `c` → ZoneId `apse2-az3` (`ap-southeast-2b`)

## Networking CIDRs
- VPC CIDR: `10.240.0.0/16`
- Public subnets:
  - `public-a`: `10.240.0.0/24`
  - `public-b`: `10.240.32.0/24`
  - `public-c`: `10.240.64.0/24`
- Private subnets:
  - `private-a`: `10.240.16.0/24`
  - `private-b`: `10.240.48.0/24`
  - `private-c`: `10.240.80.0/24`
- Pod CIDR: `10.200.0.0/16`
- Service CIDR: `10.32.0.0/24`

## Access & Tooling
- SSH key pair name: `kthw-lab` (generated locally as `chapter1/kthw-lab`)
- Terraform version: `1.13.3`
- AWS CLI: v2 (current install: `aws-cli/2.28.5`)
- `jq`: `1.7.1`

## Tagging & Naming
- Default tags: `Project=K8sHardWay`, `Env=Lab`, `managed-by=terraform`, `chapter=1`
- Resource prefix: `kthw`
- Node hostnames: `cp-{a,b,c}`, `worker-{a,b,c}`

## Outbound Internet Strategy
- Managed NAT gateway enabled in public subnet suffix `a`
- Elastic IP allocated specifically for NAT usage

## Security Considerations
- Administrative CIDR list to be supplied at apply time (currently empty)
- NodePort access CIDRs default to empty; populate when exposing workloads

Keep this file aligned with Terraform variable defaults when changes occur.
