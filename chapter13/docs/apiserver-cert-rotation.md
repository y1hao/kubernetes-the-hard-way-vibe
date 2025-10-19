# Kube-apiserver Certificate Rotation (Public Endpoint)

Use this procedure after updating `chapter3/pki/apiserver/apiserver.pem` to include the public NLB hostname.

## 1. Sync repository to the bastion
Ensure the bastion has the refreshed certificate and key (e.g., `git pull` from this repo).

## 2. Dry-run distribution (optional)
From the bastion, preview the copy operations:
```bash
python3 chapter3/scripts/distribute_pki.py \
  --manifest chapter3/pki/manifest.yaml \
  --nodes cp-a cp-b cp-c \
  --ssh-key chapter1/kthw-lab \
  --dry-run
```

## 3. Distribute the updated cert/key
Run the distribution for the control-plane nodes:
```bash
python3 chapter3/scripts/distribute_pki.py \
  --manifest chapter3/pki/manifest.yaml \
  --nodes cp-a cp-b cp-c \
  --ssh-key chapter1/kthw-lab
```
The manifest now pins owner/group to `kube-apiserver`, so the files land with the proper ownership automatically.

## 4. Restart kube-apiserver on each control plane
```bash
for node in 10.240.16.10 10.240.48.10 10.240.80.10; do
  ssh -i chapter1/kthw-lab ubuntu@${node} \
    'sudo systemctl restart kube-apiserver && sudo systemctl --no-pager status kube-apiserver'
done
```
Adjust the IPs if control-plane addressing changes.

## 5. Validation
- Confirm SANs include the public NLB hostname:
  ```bash
  ssh -i chapter1/kthw-lab ubuntu@10.240.16.10 \
    'sudo openssl x509 -in /var/lib/kubernetes/apiserver.pem -noout -text | grep -F "kthw-public-api"'
  ```
- Verify the API is healthy from each node:
  ```bash
  ssh -i chapter1/kthw-lab ubuntu@10.240.16.10 \
    'sudo kubectl --kubeconfig /var/lib/kubernetes/admin.kubeconfig get --raw=/livez'
  ```
- After generating the internet-facing kubeconfig, test from your workstation against the public NLB endpoint.
