# Solution: Enable Metrics And Debug Logging

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks five things: the log level and lease limits in the configuration, the telemetry settings in the configuration, an unauthenticated metrics request on the running server, debug lines in the log, and a Ready, unsealed server on its original data.

## Step 1: Save the current values

```sh
helm get values openbao -n openbao -o yaml > my-values.yaml
```

The file holds the values that were set at install, including the server configuration under `server.standalone.config`.

## Step 2: Edit the configuration

In `my-values.yaml`, add the three top-level settings and the `telemetry` block, and add a `telemetry` block inside the listener. The result must look like this inside `config`:

```hcl
ui = true
log_level = "debug"
default_lease_ttl = "2h"
max_lease_ttl = "48h"
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname          = true
}
listener "tcp" {
  tls_disable     = 1
  address         = "[::]:8200"
  cluster_address = "[::]:8201"
  telemetry {
    unauthenticated_metrics_access = true
  }
}
storage "raft" {
  path    = "/openbao/data"
  node_id = "openbao-0"
}
api_addr     = "http://openbao.localtest.me:8200"
cluster_addr = "http://openbao-0.openbao-internal:8201"
```

Keep the indentation of the surrounding YAML. Everything under `config: |` is one block of text.

## Step 3: Apply and restart

The chart uses the `OnDelete` update strategy, so `helm upgrade` changes the ConfigMap and does not restart the pod:

```sh
helm upgrade openbao openbao/openbao --version 0.30.4 -n openbao -f my-values.yaml
kubectl -n openbao delete pod openbao-0
```

## Step 4: Check and unseal

When the new pod runs, check the configuration it started with, then start the port-forward again in your second terminal and unseal:

```sh
kubectl -n openbao exec openbao-0 -- bao operator validate-config -config=/tmp/storageconfig.hcl
export BAO_ADDR=http://openbao.localtest.me:8200
bao operator unseal "$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.unseal-key}' | base64 -d)"
```

## Step 5: Prove each setting

```sh
curl -s -o /dev/null -w '%{http_code}\n' "$BAO_ADDR/v1/sys/metrics?format=prometheus"
kubectl -n openbao logs openbao-0 --tail=5
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
bao kv get secret/inventory/db
```

The request prints `200`, the log shows debug lines, and the secret is still there. Send the lab for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Put `unauthenticated_metrics_access` in the top-level `telemetry` block | The setting is ignored there; the request without a token still answers `403` |
| Edit the ConfigMap with `kubectl edit` | The next `helm upgrade` overwrites it |
| Run `helm upgrade` without deleting the pod | The old process keeps its old configuration; the unauthenticated request fails |
| Initialize the server again | The cluster ID changes and the secret is gone |

## Common mistakes

- Forgetting to unseal after the restart.
- Forgetting to restart the port-forward after the pod was replaced.
- Leaving out `--version 0.30.4`, which may upgrade the chart too.
