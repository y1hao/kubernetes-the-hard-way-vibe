# Kube-apiserver Certificate Rotation (Public Endpoint)

Follow this runbook after regenerating `chapter3/pki/apiserver/apiserver.pem` and `apiserver-key.pem` with the public NLB hostname SAN.

## 1. Stage artifacts to the bastion (from local workstation)
```bash
scp -i chapter1/kthw-lab \
  chapter3/pki/apiserver/apiserver.pem \
  chapter3/pki/apiserver/apiserver-key.pem \
  ubuntu@$(bin/terraform -chdir=chapter1/terraform output -raw bastion_public_ip):/tmp/ch13-apiserver/
```

## 2. Copy artifacts to each control plane (run on bastion)
```bash
for node in 10.240.16.10 10.240.48.10 10.240.80.10; do
  scp -i $(pwd)/chapter1/kthw-lab /tmp/ch13-apiserver/apiserver.pem \
    /tmp/ch13-apiserver/apiserver-key.pem \
    ubuntu@${node}:/tmp/
done
```

## 3. Install and restart kube-apiserver (run per control plane)
```bash
ssh -i $(pwd)/chapter1/kthw-lab ubuntu@10.240.16.10 <<'REMOTE'
sudo install -o root -g root -m 640 /tmp/apiserver.pem /var/lib/kubernetes/apiserver.pem
sudo install -o root -g root -m 600 /tmp/apiserver-key.pem /var/lib/kubernetes/apiserver-key.pem
sudo systemctl restart kube-apiserver
sudo systemctl --no-pager status kube-apiserver
REMOTE
```
Repeat for `10.240.48.10` and `10.240.80.10`.

## 4. Cleanup
```bash
ssh -i $(pwd)/chapter1/kthw-lab ubuntu@10.240.16.10 'sudo rm -f /tmp/apiserver.pem /tmp/apiserver-key.pem'
ssh -i $(pwd)/chapter1/kthw-lab ubuntu@10.240.48.10 'sudo rm -f /tmp/apiserver.pem /tmp/apiserver-key.pem'
ssh -i $(pwd)/chapter1/kthw-lab ubuntu@10.240.80.10 'sudo rm -f /tmp/apiserver.pem /tmp/apiserver-key.pem'
ssh -i $(pwd)/chapter1/kthw-lab ubuntu@$(bin/terraform -chdir=chapter1/terraform output -raw bastion_public_ip) 'rm -rf /tmp/ch13-apiserver'
```

## 5. Validation
```bash
ssh -i $(pwd)/chapter1/kthw-lab ubuntu@10.240.16.10 \
  'sudo openssl x509 -in /var/lib/kubernetes/apiserver.pem -noout -text | grep -E "DNS:|IP Address"'
```
Confirm the public NLB hostname appears in the SAN list.
