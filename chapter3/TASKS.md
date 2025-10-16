# Chapter 3 Execution Plan — Build the PKI

## Prerequisites
1. **Tooling**: Ensure `cfssl` and `cfssljson` binaries are available in `bin/` or on PATH; verify `openssl` for validation.
2. **Repository structure**: Create baseline directories `chapter3/pki/`, `chapter3/pki/ca/`, `chapter3/pki/apiserver/`, `chapter3/pki/kubelet/`, `chapter3/pki/kube-proxy/`, `chapter3/pki/controller-manager/`, `chapter3/pki/scheduler/`, `chapter3/pki/admin/`, `chapter3/encryption/`, and `chapter3/encryption/keys/` with restrictive permissions.

## Execution Steps
1. **Root CA material**
   - Write the `cfssl` CSR JSON for the root CA (CN `kthw-root`) and generate the RSA 2048 key/cert pair into `chapter3/pki/ca/`.
2. **Component certificate templates**
   - Author CSR JSON templates for apiserver, kube-controller-manager, kube-scheduler, kube-proxy, admin, and kubelets (parameterised for per-node SANs where needed).
3. **kube-apiserver certificate**
   - Render the apiserver CSR with SANs per ADR 003 and issue the cert using the root CA; store outputs under `chapter3/pki/apiserver/`.
4. **Controller and scheduler certs**
   - Generate certificates for kube-controller-manager and kube-scheduler using their dedicated CSR JSON files; place artifacts in their respective directories.
5. **kube-proxy client cert**
   - Issue the kube-proxy certificate/key and record the outputs under `chapter3/pki/kube-proxy/`.
6. **Node kubelet certs**
   - For each node (`cp-a`, `cp-b`, `cp-c`, `worker-a`, `worker-b`), generate a CSR JSON with the hostname, FQDN, and IP SANs, then issue the certs under `chapter3/pki/kubelet/<node>/`.
7. **Admin client cert**
   - Issue the admin certificate (CN `admin`, O `system:masters`) and store results in `chapter3/pki/admin/`.
8. **Encryption configuration**
   - Generate a random 32-byte key, base64-encode it into `chapter3/encryption/encryption-config.yaml` using the `aescbc` provider, and save the raw key to `chapter3/encryption/keys/aescbc.key`.
9. **Manifest and documentation**
   - Populate `chapter3/pki/manifest.yaml` listing each cert/key, intended destination paths on nodes, and handling notes; draft `chapter3/REVOCATION.md` detailing revocation and rotation procedures.

## Validation Steps
1. Run `cfssl certinfo` or `openssl x509 -text -noout -in` on every issued certificate to confirm SANs and OUs match decisions.
2. Execute `openssl verify -CAfile chapter3/pki/ca/ca.pem` against all non-CA certs to ensure trust chain integrity.
3. Confirm file permissions (e.g., `chmod 600` for key files) and directory ownership expectations documented for distribution.
