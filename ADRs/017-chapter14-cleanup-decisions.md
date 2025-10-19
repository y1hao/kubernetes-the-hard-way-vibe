# ADR: Chapter 14 Cleanup and Final-State Documentation Decisions

## Status
Accepted

## Context
Chapter 14 closes out the hard-way build by documenting the teardown and final-state posture. We need clear guidance on how operators should dismantle the environment, which resources to verify, and how to capture the finished architecture without introducing extra tooling maintenance.

## Decision
- Provide the cleanup workflow as copy-pasteable command blocks inside the Chapter 14 documentation rather than committing an executable script. Operators can review and run the steps manually, preserving transparency and avoiding drift.
- Maintain the AWS resource inventory as a static, human-owned checklist that describes what to confirm before and after teardown. No helper scripts or automated discovery tooling will be shipped for this phase.
- Embed the final-state architecture recap directly in `ARCHITECTURE.md`. Replace the existing ASCII diagram with a Mermaid-based VPC/topology diagram, add a second Mermaid diagram that illustrates the components running on each node, and update any sections that are now inaccurate based on the latest ADRs.
- Skip additional pre-teardown safeguards (etcd snapshots, kubeconfig backups) for this environment because the cluster will be destroyed permanently once Chapter 14 completes.

## Consequences
- Operators retain full visibility into the teardown flow and can adjust commands as needed without reverse-engineering a wrapper script.
- Resource inventory accuracy depends on manual updates, so diligence is required when AWS objects change.
- `ARCHITECTURE.md` becomes the single source of truth for both network topology and runtime layout, benefiting future readers even after the teardown.
- Accepting teardown without new backups means there is no recovery path once the cleanup steps run; this matches the user’s intent.

## Follow-up
- Document the copy-pasteable teardown commands and the resource checklist in the Chapter 14 materials.
- Refresh `ARCHITECTURE.md` diagrams and text as part of the Chapter 14 execution plan.
- Ensure the Chapter 14 summary in `README.md` captures the outcomes once work is complete.
