# Chapter 4 — etcd Cluster

This chapter brings up the three-node etcd cluster on the control plane instances using the TLS materials from Chapter 3 and the enhanced distribution tooling.

## Outputs
- etcd v3.5.12 binaries installed at `/usr/local/bin/` on `cp-a`, `cp-b`, `cp-c`.
- Systemd unit and environment files under `/etc/etcd/` with node-specific peer/client settings.
- TLS assets for server, peer, and client authentication in `/etc/etcd/pki/`.
- Bootstrap helper script `chapter4/scripts/bootstrap_etcd_node.sh` for reproducible node bring-up.

## Process Overview
1. Generated etcd peer/server/client certificates with `cfssl` using the Chapter 3 root CA.
2. Extended `chapter3/scripts/distribute_pki.py` to handle multiple manifests and directory payloads, enabling reuse of the inventory-aware workflow.
3. Authored systemd unit, env files, and validation profile under `chapter4/config/`.
4. Populated `chapter4/manifest.yaml` so binaries, configs, and TLS material can be pushed via the distribution tool.
5. Staged etcd v3.5.12 binaries locally (`chapter4/bin/`) and distributed them to each control plane node.
6. On each node:
   - Pre-created the `etcd` system account.
   - Ran the manifest-driven distribution.
   - Executed `bootstrap_etcd_node.sh` to fix ownership, reload systemd, and start the service.

## Validation
- `systemctl is-active etcd` returns `active` on `cp-a`, `cp-b`, and `cp-c`.
- `etcdctl --endpoints=https://10.240.16.10:2379,https://10.240.48.10:2379,https://10.240.80.10:2379 --cacert=/etc/etcd/pki/ca.pem --cert=/etc/etcd/pki/etcd-client.pem --key=/etc/etcd/pki/etcd-client-key.pem endpoint health` reports all members healthy.
- `etcdctl ... member list -w table` shows three started voters with one elected leader.

## Follow-up
- Automate account pre-creation or adjust distribution permissions to avoid manual user creation before transfers.
- Consider wrapping the bastion-side binary staging in a helper make target/script to streamline future upgrades.
