# Autopilot And Maintenance

Reading `list-peers` tells you who the members are. It does not tell you whether they are healthy. **Autopilot** is the part of Integrated Storage that watches the health of the nodes and can act on it. It is on by default in a Raft cluster.

## The state report

<!-- astrona:playground:renew -->

```sh
bao operator raft autopilot state
```

The report shows whether the cluster is `Healthy`, how many failures it tolerates (`Failure Tolerance`), the leader, and each server with its health, its status (leader, voter or non-voter) and how far its log is behind the leader. A node that is behind or has not answered recently is reported as unhealthy.

The settings of Autopilot are read and changed with:

```sh
bao operator raft autopilot get-config
bao operator raft autopilot set-config -cleanup-dead-servers=true -dead-server-last-contact-threshold=24h -min-quorum=3
```

- `cleanup-dead-servers` lets Autopilot remove nodes that have been gone longer than `dead-server-last-contact-threshold`. It is off by default.
- `min-quorum` is the minimum number of voters that must exist before Autopilot removes anyone. Set it to the size you expect, so a mistake cannot shrink the cluster.
- `last-contact-threshold` and `max-trailing-logs` decide when a node counts as unhealthy.

Automatic removal is convenient and also risky: a network split can make healthy nodes look dead. Turn it on only with a `min-quorum` that protects the majority.

## Planned maintenance

For a planned change to the pods, such as a new image version, work one node at a time:

1. Check `autopilot state` and wait until `Healthy` is `true`.
2. Update a standby node first. With the chart's `OnDelete` update strategy, delete one standby pod; the new pod starts with the new version.
3. Unseal the pod and wait until the state is healthy again.
4. Repeat for the other standby.
5. Make the leader step down with `bao operator step-down`, and update it last.

Take a snapshot before you start. The order keeps two nodes of three running at every moment.

## Adding a node

Raise `server.ha.replicas` in the values, run `helm upgrade`, and the new pod starts and joins through `retry_join`. Unseal it. A new voter changes the quorum: from three to four voters the quorum becomes three, so four nodes tolerate no more failures than three. Add nodes in pairs, to go from three to five.

## Common pitfalls

> [!WARNING]
> - **Updating the leader first.** Every update then causes an election at the worst moment.
> - **Turning on `cleanup-dead-servers` without `min-quorum`.** A network split can remove healthy nodes.
> - **Going from three to four nodes.** It adds a node that costs resources and adds no failure tolerance.
