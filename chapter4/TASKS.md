# Chapter 4 Execution Plan — etcd Cluster

## Prerequisites
1. Verify the Chapter 3 root CA, cfssl tooling, and `chapter2/inventory.yaml` are present on the bastion.
2. Download the etcd v3.5.12 release tarball to `artifacts/etcd/` and ensure checksum verification tooling is available.
3. Confirm control plane nodes (`cp-a`, `cp-b`, `cp-c`) are reachable via SSH from the bastion.

## Execution Steps
1. **Generate etcd certificates**
   - Create cfssl CSR templates for etcd peer, server, and client certificates using the Chapter 3 root CA; store outputs under `chapter4/pki/`.
   - Issue per-node peer/server certs keyed to hostname/FQDN/IP combinations and a client cert for etcdctl/system components.
2. **Enhance distribution tooling**
   - Extend `chapter3/scripts/distribute_pki.py` (or refactor into a shared module) to consume a new `chapter4/manifest.yaml` describing etcd binaries/configs and support directory/file deployments.
3. **Prepare etcd configuration assets**
   - Author systemd unit files, environment files, and configuration scripts under `chapter4/config/`, parameterised for per-node peer URLs and data directories.
4. **Create the etcd manifest**
   - Document all files to distribute (binaries, configs, certs) in `chapter4/manifest.yaml`, referencing inventory node names and destination paths.
5. **Distribute and install on cp-a**
   - Use the enhanced distribution tooling to push binaries, configs, and TLS assets to `cp-a`; enable and start the etcd service and verify status locally.
6. **Repeat rollout for cp-b and cp-c**
   - Run the same distribution process for `cp-b` and `cp-c`, ensuring the cluster forms and all members report healthy.
7. **Capture operational validation**
   - Run `etcdctl --endpoints=https://<private-ips>:2379 endpoint status/health` from each control plane node and record expected outputs in `chapter4/README.md`.

## Validation Steps
1. Confirm `systemctl status etcd` reports active on all three control plane nodes after distribution.
2. Execute `etcdctl member list` using the client cert bundle to ensure all three members are present and voters.
3. Document any manual intervention or deviations encountered during installation for future runs.
