# Certificate Revocation & Rotation Playbook

## Scope
Covers material issued in Chapter 3 for the Kubernetes cluster: root CA, kube-apiserver, controller-manager, scheduler, kube-proxy, kubelet (per node), admin client, and the encryption configuration key.

## Root CA
- Treat `chapter3/pki/ca/ca-key.pem` as offline-only. Do not distribute.
- Store an encrypted backup of the root key outside the repository (e.g., hardware token or password manager with file vault).
- To rotate the root CA:
  1. Generate a new CA pair following Step 1.
  2. Re-issue every leaf certificate using the new CA.
  3. Update kubeconfigs and service manifests to trust the new CA bundle.
  4. Redeploy components with the regenerated artifacts.

## Leaf Certificates
- Revocation is handled operationally by removing the cert/key from nodes and reissuing a replacement; CRLs are optional for this lab.
- For compromised component keys:
  1. Delete the affected key/cert from the node.
  2. Re-run the relevant `cfssl gencert` with updated serial (optionally adjust manifest notes).
  3. Update the kubeconfig or service referencing the certificate.
  4. Restart the component.

## Kubelet Certificates
- Compromise of a node key requires rotating the kubelet cert and updating the node configuration.
- Optionally, use kubelet TLS bootstrap in later chapters to automate renewals; this ADR intentionally keeps manual issuance.

## Encryption Configuration
- Rotate `chapter3/encryption/keys/aescbc.key` by generating a new key, appending it to the provider list as `key2`, rolling the apiserver, then removing the old key.
- Always coordinate rotation with etcd snapshot/restore procedures to ensure no secrets remain encrypted with retired keys.

## Logging
- Record each issuance/rotation event (timestamp, operator) in an ops log. For this chapter, append notes to `chapter3/pki/manifest.yaml` or maintain a separate runbook.

## Validation
- Post-rotation, rerun the Chapter 3 validation commands (`cfssl certinfo`, `openssl verify`) to confirm certificate integrity and trust chains.
