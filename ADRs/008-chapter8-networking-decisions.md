# ADR: Chapter 8 Cluster Networking Decisions

## Status
Accepted

## Context
Chapter 8 introduces pod networking for the cluster. Control plane and worker nodes are already provisioned (Chapters 1–7) and today they register as `NotReady` because no CNI plugin manages pod CIDR routing. The specification calls for Calico with VXLAN encapsulation, no dependency on cloud provider integration, and readiness for future NetworkPolicy work. We needed to agree on the exact release, encapsulation settings, MTU management, and how to capture NetworkPolicy guidance before rendering manifests and authoring the execution plan.

## Decision
- **Calico release**: Deploy Calico `v3.28.2` using the upstream Tigera manifest as our base, ensuring compatibility with Kubernetes v1.31.1 and recent Felix improvements.
- **Encapsulation mode**: Run Calico in VXLAN encapsulation only. Keep the default node-to-node mesh (no external BGP peers) and omit Typha because the cluster size is well below the scale where API watch fan-out becomes an issue.
- **MTU strategy**: Rely on Calico's automatic MTU detection. AWS ENA interfaces expose 9001-byte MTU, and Calico will derive the correct pod-facing MTU by subtracting VXLAN overhead without hard-coding a value.
- **NetworkPolicy artifacts**: Provide Markdown guidance in Chapter 8 documenting baseline policy patterns and defer publishing concrete policy manifests to Chapter 11, which covers security hardening.
- **Artifact layout**: Store the rendered manifest and notes under `chapter8/` (`chapter8/calico.yaml`, `chapter8/README.md`), matching prior chapter conventions.

## Consequences
- Sticking to the vendor manifest keeps alignment with Tigera's tested deployment flow while letting us layer CIDR and configuration overrides locally.
- VXLAN-only encapsulation satisfies the spec's "no cloud provider" requirement and avoids the operational overhead of Typha or BGP for this small cluster.
- MTU auto-detect avoids premature tuning while still tracking interface changes if AWS updates the underlying MTU.
- Documenting policy guidance now while deferring YAML keeps Chapter 8 focused on networking bring-up and leaves detailed enforcement to Chapter 11.
- The chosen artifact layout makes downstream scripting consistent with earlier chapters and simplifies references in TASKS and README updates.

## Follow-up
- Render Calico `v3.28.2` manifest with cluster-specific Pod CIDR substitutions and store it in `chapter8/calico.yaml`.
- Author Chapter 8 TASKS documenting how to apply the manifest, validate Calico readiness, and run cross-node connectivity checks.
- Draft Chapter 8 README with validation commands and NetworkPolicy guidance notes.
- Revisit MTU explicitly if future workload testing shows fragmentation or if Chapter 11 introduces stricter network policy components that benefit from tuned values.
