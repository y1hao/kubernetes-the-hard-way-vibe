# ADR: Chapter 12 Documentation-Only Scope for Backups, Upgrades, and DR

## Status
Accepted

## Context
The SPEC Chapter 12 workstream expects us to automate etcd snapshots, produce upgrade runbooks, and validate disaster recovery drills. However, the current project focus is on prior chapters that directly support day-to-day cluster operations. Executing the full resiliency program now would require access to production-like infrastructure, maintenance windows, and additional tooling we have not prioritised. The user is satisfied with capturing the approach as documentation for later execution, allowing us to preserve momentum while still clarifying the path forward.

## Decision
- Treat Chapter 12 as a planning/documentation exercise only for the current phase.
- Capture the intended workstreams, artifacts, validation steps, and prerequisites in `chapter12/README.md` so the team can pick up the effort when ready.
- Defer hands-on automation (snapshot scripts, upgrade playbooks, node replacement tooling) until we explicitly schedule the resiliency work and have bastion/cluster time allocated.
- Revisit the decision once we are ready to staff the resilience milestone or after completing remaining SPEC chapters.

## Consequences
- We retain clarity on how to implement Chapter 12 tasks without investing time in cluster-touching changes today.
- No automated backups, upgrade rehearsals, or DR drills are in place yet; the cluster remains vulnerable to data loss or slow recovery until we execute the documented plan.
- Future engineers have a starting point in the documentation but must budget time to translate it into scripts, IaC, and validated procedures.
- Related infrastructure choices (snapshot storage, cron placement, maintenance windows) remain unresolved and must be addressed during the eventual implementation.

## Follow-up
- Finalise ownership, storage targets, and scheduling for the resiliency work before starting implementation.
- Extend the documentation into concrete scripts and runbooks when Chapter 12 execution is prioritised.
- Add validation timelines to TASKS.md when we initiate the resiliency milestone.
