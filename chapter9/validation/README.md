# Validation Helpers

## Test Pod
- Manifest: `chapter9/validation/test-client.yaml`
- Launch:
  ```bash
  chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig apply -f chapter9/validation/test-client.yaml
  chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig wait pod/dns-metrics-check --for=condition=Ready --timeout=180s
  ```

## DNS Resolution Check
- From the test pod:
  ```bash
  chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig exec dns-metrics-check -- nslookup kubernetes.default
  ```

## Metrics API Check
- Retrieve node metrics:
  ```bash
  chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig top nodes
  ```

## Cleanup
- Remove the helper pod when done:
  ```bash
  chapter5/bin/kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig delete -f chapter9/validation/test-client.yaml
  ```
