# Summary

A seal protects the root key and gives it back to OpenBao at start. The default Shamir seal needs a threshold of people to enter key shares after every restart. Other seals use an outside key: the Transit engine of another OpenBao server, a static key, a hardware security module through PKCS#11, or the key management service of a cloud provider. The choice is written in a `seal` block of the configuration file, and a file without one uses Shamir. With an outside seal, OpenBao calls the seal service at start, decrypts the root key and unseals itself, so the service must be reachable and its key must never be deleted.

A server with an auto-unseal seal is initialized with recovery keys instead of unseal keys, set with `-recovery-shares` and `-recovery-threshold`. They cannot unseal the server. They authorize operations such as `bao operator generate-root`. A running server changes its seal with a seal migration: take a snapshot, change the `seal` block, restart, and enter the old shares with `bao operator unseal -migrate`. The old unseal shares then work as recovery keys.

Integrated Storage replicates data with the Raft protocol. One node is active and serves requests, the others are standby nodes that forward requests to it. A cluster needs a majority of its nodes, so three or five nodes are the normal sizes. `bao operator raft list-peers`, `bao status` and `sys/leader` show the cluster, and `bao operator step-down` hands the active role to another node. Replication protects against a failing node and not against a mistake, because a mistake is replicated too. `bao operator raft snapshot save` writes a point-in-time copy of all data, and `bao operator raft snapshot restore` puts it back. A snapshot is only readable with the unseal keys that match it.

The key facts to remember:

- No `seal` block means Shamir.
- Recovery keys authorize sensitive operations and never unseal.
- Use three or five nodes; an even number adds no safety.
- Replication is not a backup; take snapshots and practice the restore.

<!-- astrona:playground:destroy -->
