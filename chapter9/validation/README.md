# Validation Helpers

## Test Pod
- Manifest: `chapter9/validation/test-client.yaml`
- Launch:
  ```bash
  k apply -f chapter9/validation/test-client.yaml
  k wait pod/dns-metrics-check --for=condition=Ready --timeout=180s
  ```

## DNS Resolution Check
- From the test pod:
  ```bash
  k exec dns-metrics-check -- nslookup kubernetes.default.svc.cluster.local
  ```
  BusyBox does not auto-append search domains, so prefer the full service name.

## Metrics API Check
- Retrieve node metrics:
  ```bash
  k top nodes
  ```

## Cleanup
- Remove the helper pod when done:
  ```bash
  k delete -f chapter9/validation/test-client.yaml
  ```
