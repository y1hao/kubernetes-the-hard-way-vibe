# ADR: Chapter 4 etcd Decisions

## Status
Accepted

## Context
Chapter 4 introduces the etcd control plane for the cluster. We needed to agree on the etcd release, data directory layout, how to issue TLS assets, and the automation approach for distributing binaries and configuration so implementation can proceed without ambiguity.

## Decision
- **etcd release**: Install etcd v3.5.12 across all three control-plane nodes. This aligns with the latest stable 3.5 branch compatible with the Kubernetes versions we plan to run.
- **Data directory**: Use `/var/lib/etcd` on the existing root volume for member data, deferring dedicated EBS volumes until we have a clear requirement.
- **TLS material**: Issue etcd peer and client certificates using the Chapter 3 root certificate authority via `cfssl`, keeping trust consistent with other control-plane components.
- **Distribution approach**: Extend the manifest-driven Python distribution tooling introduced in Chapter 3 to handle etcd binaries, configuration, and TLS assets. This keeps deployments repeatable from the bastion and reuses our inventory-aware workflow.

## Consequences
- Staying on etcd v3.5.12 ensures upstream feature compatibility while receiving recent bug and security fixes.
- Relying on the root volume simplifies bootstrap, but we must monitor disk usage and document the migration path to dedicated storage if needed later.
- Reusing the existing CA provides a single source of trust; regenerating the root would require reissuing etcd certs along with other cluster credentials.
- Enhancing the Python distribution utility lets us manage etcd rollouts alongside PKI distribution, reducing bespoke scripting and supporting future reuse for other components.

## Follow-up
- Update the Chapter 3 PKI pipeline to generate the required etcd peer and client certificates using `cfssl` templates.
- Extend the distribution script to understand etcd artifacts and the Chapter 4 manifest structure.
- Document monitoring and backup expectations (e.g., snapshots) as we build out the etcd automation in subsequent tasks.
