# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Raft high availability

## Scenario

The inventory team runs OpenBao as one node, and an outage of that node stops all work. The platform team decided to run three nodes with Raft. The data in the existing node, including `secret/inventory/db`, must be kept: do not install a new cluster.

For this lab only, the unseal key and the root token are in the Secret `openbao-init` (keys `unseal-key` and `root-token`).

Reach the server with `kubectl -n openbao port-forward svc/openbao 8200:8200` in a second terminal and `export BAO_ADDR=http://openbao.localtest.me:8200`.

## Your task

1. Change the Helm release `openbao` in the namespace `openbao` so that it runs three Raft nodes (`server.ha.enabled`, `server.ha.raft.enabled`, `replicas: 3`, `setNodeId: true` and a `retry_join` block for each node).
2. Make the existing node use the new configuration, and unseal it again.
3. Unseal the two new nodes so that they take part in the cluster.

## Constraints

- Do not run `bao operator init` again, and do not delete the persistent volume of `openbao-0`.
- Use the chart version `0.30.4` and the image tag `2.7.1`.

## Done when

- The Raft configuration lists three voting nodes.
- `openbao-0`, `openbao-1` and `openbao-2` are all unsealed.
- The cluster ID is unchanged and `secret/inventory/db` still holds its original value.
