# Seals, High Availability And Backups

The default way to unseal OpenBao needs people: after every restart, enough key holders must enter their shares. That works for a small installation, but it does not suit a platform that restarts servers all day. This module shows the other ways to unseal, how several servers share one data set, and how to back that data up and bring it back.

Keep one sentence in mind: **the seal decides who can start the server, Raft decides where the data lives, and a snapshot is the only copy that survives losing both.**

The module has four parts. **Seal Types And Auto-Unseal** compares the Shamir seal with seals that use an outside key and shows what the `seal` block looks like. **Recovery Keys And Seal Migration** explains what replaces the unseal keys when the server unseals itself, and how a server moves from one seal to another. **Raft Cluster And High Availability** shows how several servers elect one active server and how to read the cluster. **Raft Snapshots** saves and restores the whole data set; a graded lab follows it.

## Learning objectives

After this module you can:

- Name the seal types OpenBao supports and write the `seal` block of a configuration.
- Explain how auto-unseal changes initialization, and what recovery keys can and cannot do.
- Describe the steps of a seal migration.
- Explain active and standby servers, Raft quorum, and read the cluster with `bao operator raft list-peers`.
- Make a server give up the active role with `bao operator step-down`.
- Save a snapshot with `bao operator raft snapshot save` and restore it with `bao operator raft snapshot restore`.

## Before you start

You need to know the three layers of keys (encryption keys, root key and unseal key), what sealed means, and how to use `bao status`. You should be able to read the server configuration file.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`. The server is initialized with one key share and unsealed. For this lab only, the unseal key and the root token are in the Kubernetes Secret `openbao-init` (keys `unseal-key` and `root-token`); a real installation never keeps them in the cluster. The server has one node, so a cluster of several servers is described in the text and cannot be seen in full.

The environment installs the `bao` command-line tool on your machine. Start the port-forward in a second terminal (`kubectl -n openbao port-forward svc/openbao 8200:8200`) and set `export BAO_ADDR=http://openbao.localtest.me:8200`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
