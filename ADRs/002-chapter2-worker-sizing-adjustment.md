# ADR: Chapter 2 Worker Sizing Adjustment

## Status
Accepted

## Context
While drafting Chapter 2 we initially selected six `t3.medium` instances to keep both control plane and worker roles homogeneous (ADR 001). After reviewing the workloads planned for this lab we realised the worker nodes will host only light demo pods, so the extra memory on `t3.medium` is unused. We also reviewed the cost of keeping three workers and determined that the third worker adds spend without improving our near-term goals, given that we are not running production traffic.

## Decision
- **Control plane sizing**: Keep the three control plane nodes on `t3.medium` to preserve etcd and API server headroom.
- **Worker sizing**: Move worker nodes to `t3.small` (2 vCPU, 2 GiB RAM). This keeps the CPU layout consistent with the control plane while halving per-node cost.
- **Worker count**: Operate with two worker nodes (`worker-a` in AZ a and `worker-b` in AZ b). The AZ c worker slot remains available for future expansion but is not provisioned in Chapter 2 to reduce cost.
- **Terraform implementation**: Introduce distinct instance type variables per role and remove the `worker-c` entry from the static node map so Terraform only provisions the two workers above.
- **Documentation**: Update inventory, task notes, and downstream references so that only two workers are assumed for validation and operations.

## Consequences
- Monthly spend drops by roughly one third for the worker fleet (two `t3.small` instead of three `t3.medium`), making the lab cheaper to keep running.
- We forfeit worker capacity in AZ c, which reduces fault tolerance for user workloads; losing AZ a or AZ b will now temporarily remove all worker capacity. Control plane quorum remains unaffected.
- Additional workloads may need careful resource requests to avoid memory pressure on the smaller worker nodes; baseline DaemonSets fit comfortably but heavy demos should be limited.
- Future scaling can reintroduce the AZ c worker (or larger instance types) without redesigning the subnet layout because the original static IP range is untouched.

## Follow-up
- Update Chapter 2 Terraform to honour distinct instance type variables and drop the third worker resource.
- Refresh `chapter2/inventory.yaml`, `chapter2/notes.md`, and any validation scripts to reflect the two-worker layout.
- Amend Chapter 2 documentation (SPEC, TASKS) so engineers following the guide expect two workers on `t3.small` by default.
- Revisit the readiness and scheduling strategy in later chapters to confirm two workers suffice for add-ons and demo workloads.
