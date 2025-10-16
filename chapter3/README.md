# Chapter 3 — Build the PKI

This chapter establishes the full certificate authority chain, component certificates, and secrets encryption configuration required for the Kubernetes control plane and worker nodes. All assets were generated with `cfssl` 1.6.5 following the decisions captured in `ADRs/003-chapter3-pki-decisions.md`.

## Outputs
- Root CA material under `chapter3/pki/ca/` (RSA 2048, single-tier authority).
- Component certificates for kube-apiserver, controller-manager, scheduler, kube-proxy, admin, and per-node kubelets under `chapter3/pki/`.
- Distribution manifest `chapter3/pki/manifest.yaml` documenting target hosts and filesystem paths.
- AES-CBC secrets encryption key and configuration at `chapter3/encryption/`.
- Revocation and rotation guidance in `chapter3/REVOCATION.md`.

## Generation Process
1. Ensure `cfssl` and `cfssljson` are installed and on PATH.
2. Generate the root CA from `chapter3/pki/ca/ca-csr.json` with:
   ```bash
   cfssl gencert -initca chapter3/pki/ca/ca-csr.json | cfssljson -bare chapter3/pki/ca/ca
   ```
3. Issue component certs using the CA config `chapter3/pki/ca/ca-config.json`:
   - kube-apiserver with SANs listed in `chapter3/pki/apiserver/apiserver-hosts.json`.
   - controller-manager, scheduler, kube-proxy, and admin via their CSR JSON files and the `client` profile.
   - kubelets per node with CSR specs in `chapter3/pki/kubelet/<node>/csr.json` using the `kubernetes` profile.
4. Create the secrets encryption key:
   ```bash
   openssl rand -out chapter3/encryption/keys/aescbc.key 32
   ```
   Then render `chapter3/encryption/encryption-config.yaml` with the base64-encoded key (see `chapter3/TASKS.md`).
5. Update `chapter3/pki/manifest.yaml` and `chapter3/REVOCATION.md` with handling notes.

## Validation
- Verify certificate trust with:
  ```bash
  openssl verify -CAfile chapter3/pki/ca/ca.pem <cert.pem>
  ```
- Inspect SANs and subject details via `cfssl certinfo -cert <cert.pem>` or `openssl x509 -in <cert.pem> -noout -text`.

## Handling & Security
- Private keys (`*-key.pem`), the AES key, and the encryption config are ignored via `.gitignore`; do not commit them.
- Distribute artifacts according to `chapter3/pki/manifest.yaml`, applying restrictive permissions (`600`) on keys.
- For rotations or revocations, follow `chapter3/REVOCATION.md` and regenerate affected materials with `cfssl`.

## Distribution Script
- Running on the bastion, ensure the repo (including generated keys) is present and `PyYAML` is available (`pip install pyyaml` if needed).
- From the repository root, execute a dry run to review actions:
  ```bash
  python3 chapter3/scripts/distribute_pki.py --dry-run
  ```
- Distribute to all nodes:
  ```bash
  python3 chapter3/scripts/distribute_pki.py
  ```
  The script reads `chapter3/pki/manifest.yaml` and `chapter2/inventory.yaml`, copies artifacts via `scp`, and moves them into place with `sudo install`. Keys land with mode `600`; public certs use `644`.
- Target specific nodes with `--nodes cp-a worker-a`, override SSH options with `--ssh-key` or `--user`, and re-run as needed after rotations.
