# Run A Three-Node OpenBao Cluster

The previous module described a Raft cluster. This module builds one. You set up three OpenBao servers with the Helm chart, join and unseal them, read the cluster, stop the leader and watch another node take over, and remove a node that is gone.

Keep one sentence in mind: **a three-node cluster keeps working while any one node is down, and it stops, without losing data, when two are down.**

The module has four parts. **Helm Values For A Raft Cluster** shows the chart settings that make three nodes. **Joining And Unsealing The Nodes** brings the second and third node in; a graded lab follows it. **Losing A Node** stops the leader and the standbys and shows the elections. **Autopilot And Maintenance** covers the cluster health report and the rules for adding and removing nodes.

## Learning objectives

After this module you can:

- Write the Helm values for a Raft cluster with `retry_join` and `setNodeId`.
- Join a node to the cluster and unseal it, and explain why each node is unsealed on its own.
- Read the cluster with `bao operator raft list-peers`, `bao status` and `sys/health` on each node.
- Predict what a cluster of three nodes does when one or two nodes stop.
- Remove a node that is gone with `bao operator raft remove-peer`.
- Read the Autopilot report with `bao operator raft autopilot state`.

## Before you start

You need the Raft and high-availability concepts from the previous module: active and standby nodes, quorum and the snapshot. You should be able to read a Helm values file.

Your playground is a `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, installed as a cluster of three pods: `openbao-0`, `openbao-1` and `openbao-2`. The first node is initialized and unsealed. The other two have joined the cluster and are sealed. For this lab only, the unseal key and the root token are in the Kubernetes Secret `openbao-init` (keys `unseal-key` and `root-token`); a real installation never keeps them in the cluster.

The environment installs the `bao` command-line tool on your machine. Start the port-forward in a second terminal (`kubectl -n openbao port-forward svc/openbao 8200:8200`) and set `export BAO_ADDR=http://openbao.localtest.me:8200`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
