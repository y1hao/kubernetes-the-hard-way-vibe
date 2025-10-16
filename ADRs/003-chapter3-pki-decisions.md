# ADR: Chapter 3 PKI Decisions

## Status
Accepted

## Context
Chapter 3 focuses on building the cluster Public Key Infrastructure (PKI) that will secure Kubernetes control plane and node communications. Before drafting the implementation plan, we aligned on tooling, certificate authority structure, naming, and artifact handling so automation can be scripted without rework.

## Decision
- **Tooling**: Use `cfssl` for all certificate and key generation to avoid hand-maintaining OpenSSL configuration fragments and CA databases.
- **Certificate authority**: Operate a single RSA 2048-bit root CA kept within the repository workspace during the build, with no online intermediate.
- **Artifact layout**: Store generated materials under `chapter3/pki/`, grouped by role (e.g., `ca/`, `apiserver/`, `kubelet/<node>/`, `kube-proxy/`, `controller-manager/`, `scheduler/`, `admin/`) and record delivery details in `chapter3/pki/manifest.yaml`.
- **API endpoint naming**: Standardise on `api.kthw.lab` as the canonical Kubernetes API DNS name so all FQDNs share the `.kthw.lab` suffix.
- **kube-apiserver SANs**: Include `api.kthw.lab`, the three control-plane private IPs (`10.240.16.10`, `10.240.48.10`, `10.240.80.10`), loopback `127.0.0.1`, each control-plane hostname and FQDN (`cp-{a,b,c}`, `cp-{a,b,c}.kthw.lab`), the service cluster IP `10.32.0.1`, and the well-known service DNS entries (`kubernetes`, `kubernetes.default`, `kubernetes.default.svc`, `kubernetes.default.svc.cluster.local`).
- **kubelet certificates**: Issue one cert per node with SANs covering the node hostname, FQDN (`*.kthw.lab`), and its static private IP.
- **Client identities**: Use Kubernetes-standard CN/O pairs — admin (`CN=admin`, `O=system:masters`); controller-manager (`CN=system:kube-controller-manager`); scheduler (`CN=system:kube-scheduler`); kube-proxy (`CN=system:kube-proxy`) without additional SANs.
- **Secrets encryption config**: Generate an `aescbc` provider config with a base64-encoded 32-byte key, store the config at `chapter3/encryption/encryption-config.yaml`, and keep the raw key material in `chapter3/encryption/keys/aescbc.key` with documentation on handling.
- **Revocation & rotation**: Document procedures and considerations in `chapter3/REVOCATION.md`.

## Consequences
- `cfssl` JSON templates can be scripted for each certificate class, reducing manual error compared to OpenSSL command sequences.
- A single CA simplifies issuance but concentrates trust; we must guard the root key carefully during the build.
- A consistent `.kthw.lab` namespace keeps SANs and future DNS configuration straightforward.
- Predefined SAN sets ensure apiserver and kubelet certificates cover all planned access paths, limiting future regeneration.
- Storing encryption materials and revocation notes alongside PKI artifacts keeps Chapter 3 deliverables self-contained while flagging sensitive files for secure handling.

## Follow-up
- Scaffold the `chapter3/pki/`, `chapter3/encryption/`, and supporting directories before generation.
- Capture handling guidance (permissions, distribution steps) inside `chapter3/pki/manifest.yaml` and `chapter3/REVOCATION.md` during implementation.
- Ensure `.gitignore` (if necessary) protects any files we do not want committed once generation is complete.
