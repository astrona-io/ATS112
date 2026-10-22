# Solution: Repair A Server Configuration

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: the configuration listens on `[::]:8200` and uses `/openbao/data`, `validate-config` accepts it, the pod is Ready and unsealed, and the server is the original cluster with its secret readable.

## Step 1: See the symptom

Look at the pod and ask the server for its status from inside the pod, where `BAO_ADDR` points at the local listener on port 8200:

```sh
kubectl -n openbao get pod openbao-0
kubectl -n openbao exec openbao-0 -- bao status
```

The pod is `0/1`. `bao status` inside the pod cannot connect: nothing listens on `127.0.0.1:8200`. The readiness probe runs the same command, which is why the pod is not Ready.

## Step 2: Read the configuration

Print the configuration the chart gave the pod:

```sh
kubectl -n openbao get configmap openbao-config -o jsonpath='{.data.extraconfig-from-values\.hcl}'
```

Two lines differ from the server's original setup:

- `address = "[::]:8300"` in the listener: the server listens on 8300, but the Service, the probe and every client use 8200.
- `path = "/openbao/raft"` in the Raft storage: the server looks for its data in an empty folder. On that folder it is a new, uninitialized server. The real data is still in `/openbao/data`.

The second fault is the dangerous one. If you only fixed the port, `bao status` would show `Initialized` `false`, and initializing that server would create a second, empty cluster.

## Step 3: Correct the values and restart

Save this as `openbao-values.yaml`, the original configuration:

```yaml
fullnameOverride: openbao
injector:
  enabled: false
server:
  image:
    tag: "2.7.1"
  standalone:
    enabled: true
    config: |
      ui = true

      listener "tcp" {
        tls_disable     = 1
        address         = "[::]:8200"
        cluster_address = "[::]:8201"
      }

      storage "raft" {
        path    = "/openbao/data"
        node_id = "openbao-0"
      }

      api_addr     = "http://openbao.localtest.me:8200"
      cluster_addr = "http://openbao-0.openbao-internal:8201"
  dataStorage:
    enabled: true
    size: 1Gi
ui:
  enabled: true
```

Apply it, then delete the pod, because the chart uses the `OnDelete` update strategy and does not restart it for you:

```sh
helm upgrade openbao openbao/openbao --version 0.30.4 -n openbao -f openbao-values.yaml
kubectl -n openbao delete pod openbao-0
```

## Step 4: Check the configuration and unseal

When the new pod runs, check the configuration it started with:

```sh
kubectl -n openbao exec openbao-0 -- bao operator validate-config -config=/tmp/storageconfig.hcl
```

It reports the configuration as valid. Start the port-forward again in your second terminal (it stopped with the old pod), then check the state and unseal:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
bao status
bao operator unseal "$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.unseal-key}' | base64 -d)"
```

`bao status` shows `Initialized` `true` and `Sealed` `true`: this is the original server, sealed by the restart. After the unseal it is `false`, and the pod becomes `1/1`.

## Step 5: Prove the data is there

Read the secret with the original root token:

```sh
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
bao kv get secret/inventory/db
```

It shows `username` and `password`. Send the lab for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Fix only the port, then run `bao operator init` | You create a new, empty cluster in `/openbao/raft`; the grader sees a new cluster ID and no secret |
| Edit the ConfigMap with `kubectl edit` | The next `helm upgrade` overwrites it, and the grader reads the configuration the chart manages |
| Run `helm upgrade` without deleting the pod | The old process keeps its old configuration; nothing changes |

## Common mistakes

- Forgetting to unseal after the restart.
- Forgetting to restart the port-forward after the pod was replaced.
- Running `helm upgrade` without `--version`, which may upgrade the chart too.
