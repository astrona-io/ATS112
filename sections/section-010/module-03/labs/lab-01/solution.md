# Solution: Turn A Single OpenBao Node Into A Three-Node Cluster

Work the task yourself first. Running `astrona submit -c sections/section-010/module-03/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: three voters in the Raft configuration, three unsealed pods, and the original cluster with its secret.

## Step 1: Save the values for three nodes

Save this as `ha-values.yaml`:

```yaml
fullnameOverride: openbao
injector:
  enabled: false
server:
  image:
    tag: "2.7.1"
  ha:
    enabled: true
    replicas: 3
    raft:
      enabled: true
      setNodeId: true
      config: |
        ui = true

        listener "tcp" {
          tls_disable     = 1
          address         = "[::]:8200"
          cluster_address = "[::]:8201"
        }

        storage "raft" {
          path = "/openbao/data"

          retry_join {
            leader_api_addr = "http://openbao-0.openbao-internal:8200"
          }
          retry_join {
            leader_api_addr = "http://openbao-1.openbao-internal:8200"
          }
          retry_join {
            leader_api_addr = "http://openbao-2.openbao-internal:8200"
          }
        }

        api_addr     = "http://openbao.localtest.me:8200"
        cluster_addr = "http://$(HOSTNAME).openbao-internal:8201"

        service_registration "kubernetes" {}
  dataStorage:
    enabled: true
    size: 1Gi
ui:
  enabled: true
```

Apply it:

```sh
helm upgrade openbao openbao/openbao --version 0.30.4 --namespace openbao -f ha-values.yaml
```

Then check the result:

```sh
kubectl -n openbao get pods
```

The two new pods `openbao-1` and `openbao-2` start. The existing pod `openbao-0` keeps its old configuration, because the chart's StatefulSet uses the `OnDelete` update strategy.

## Step 2: Restart and unseal the first node

```sh
kubectl -n openbao delete pod openbao-0
kubectl -n openbao wait --for=jsonpath='{.status.containerStatuses[0].started}'=true pod/openbao-0 --timeout=180s
UNSEAL="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.unseal-key}' | base64 -d)"
kubectl -n openbao exec openbao-0 -- bao operator unseal "$UNSEAL"
```

The new pod uses the same persistent volume, so it keeps its data and its node ID.

## Step 3: Unseal the new nodes

```sh
for pod in openbao-1 openbao-2; do
  kubectl -n openbao exec "$pod" -- bao operator unseal "$UNSEAL"
done
```

If the command says the node is not yet part of a cluster, wait a few seconds and repeat it. The `retry_join` blocks join the node as soon as `openbao-0` is unsealed.

## Step 4: Check and submit

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
bao operator raft list-peers
astrona submit -c sections/section-010/module-03/labs/lab-01
```

The list shows three nodes, all voters.

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Uninstall the release and install the HA values | The persistent volume is removed or a new cluster is created, and the grader finds a different cluster ID |
| Run `bao operator init` on the new pods | Each pod creates its own cluster, and the Raft configuration still has one voter |
| Skip the restart of `openbao-0` | The old configuration stays in use and the new pods have nothing to join |

## Common mistakes

- Forgetting `setNodeId: true`, so the nodes get the same ID.
- Unsealing only the first node. The two new nodes are not part of the quorum until they are unsealed.
