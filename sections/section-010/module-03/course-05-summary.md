# Summary

A Raft cluster in the Helm chart is a StatefulSet with `server.ha.enabled`, `server.ha.raft.enabled`, `replicas` and `setNodeId: true`. The `storage "raft"` block lists `retry_join` blocks that name nodes to join, and `service_registration "kubernetes"` labels the pods as active or standby. Only one node is initialized, with `bao operator init`; the others join the cluster and are unsealed on their own, because each holds the keys only in memory.

`bao operator raft list-peers` shows the members and the leader. A cluster of three tolerates one failed node and a cluster of five tolerates two. With the quorum lost, the remaining nodes refuse requests and keep their data. When the leader stops, the followers hold an election and one becomes active. A node that restarts is sealed and must be unsealed. A node that will not return is removed with `bao operator raft remove-peer`.

`bao operator raft autopilot state` reports the health of every node. Automatic removal of dead servers is off by default and needs `min-quorum` when turned on. For maintenance, update one standby at a time, wait for a healthy state, and update the leader last.

The key facts to remember:

- Initialize one node; join and unseal the rest.
- Three or five nodes; never two or four for the sake of failure tolerance.
- Never take two nodes down at once.
- Take a snapshot before maintenance.

Your playground is no longer needed. Remove it:

<!-- astrona:playground:destroy -->
