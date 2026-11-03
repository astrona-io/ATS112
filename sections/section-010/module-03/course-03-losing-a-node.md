# Losing A Node

A cluster is built for failure. This part stops nodes on purpose and shows what the cluster does, so that a real failure does not come as a surprise. Run the commands in the playground.

## Stop a follower

Find the leader with `bao operator raft list-peers`, then delete a pod that is not the leader:

<!-- astrona:playground:renew -->

```sh
kubectl -n openbao delete pod openbao-2
bao operator raft list-peers
```

Requests keep working: the cluster has two nodes left, and the quorum of three nodes is two. The new pod `openbao-2` starts with the same persistent volume, so it still has its Raft data and the node ID, and it joins again. It is sealed after the restart. Unseal it:

```sh
kubectl -n openbao exec openbao-2 -- bao operator unseal "$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.unseal-key}' | base64 -d)"
```

## Stop the leader

Delete the pod that `list-peers` shows as leader. In the example it is `openbao-0`:

```sh
kubectl -n openbao delete pod openbao-0
bao operator raft list-peers
```

For a short time no node is active. The followers notice that they no longer hear the leader, wait for a randomized election timeout, and one of them wins the election with the vote of the other. `list-peers` then shows a new leader. If the command cannot reach the server for a moment, repeat it. The port-forward points at one pod and may need a restart after that pod is deleted.

The old leader comes back as a sealed follower. Unseal it as before, and it catches up from the log. The data written while it was away is copied to it.

## Stop two nodes

With two of three nodes down, the cluster has no quorum. The remaining node cannot elect a leader or commit a write, so it refuses requests. The data is not lost: it is on the disks of all three nodes. When one more node returns and is unsealed, the quorum is back and the cluster continues. This is the reason to keep nodes on different machines or zones, so that one outage does not take two.

## Remove a node for good

If a node's volume is lost and the node will not come back, the cluster still counts it. Remove it from the configuration:

```sh
bao operator raft remove-peer openbao-2
bao operator raft list-peers
```

The list then shows two nodes, and the quorum is two of two. That cluster tolerates no failure, so add a replacement node soon. A node you remove can join again later, as a new member with an empty volume.

## What to watch

- The number of voters in `list-peers` against the number you expect.
- Pods that are Running and sealed after a restart. A sealed standby is not a failure that clients see, but the cluster has less margin.
- The health endpoint on each node: `200` for the active node, `429` for an unsealed standby, `503` for a sealed node.

## Common pitfalls

> [!WARNING]
> - **Deleting two pods at once during maintenance.** The cluster loses its quorum.
> - **Forgetting to unseal a node after it restarts.** The cluster runs with less margin than you think.
> - **Removing a node that is only down for a short time.** Remove a node only when it will not come back with its data.
