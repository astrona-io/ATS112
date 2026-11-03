# Section 010: What OpenBao Is And How It Protects Data

A secrets server is only useful if its own data is safe. If someone copies the disk of an OpenBao server, they must find nothing they can read. This section explains how OpenBao achieves that: every byte it writes passes through an encryption layer, and the key to that layer exists only in memory while the server is unsealed.

You start with what OpenBao is and how a request travels through it. Then you open the layers that protect the data: the barrier, the keyring, the root key and the unseal key, split into shares with Shamir's secret sharing. Last, you read the seal state and the health of a server, and you unseal one yourself.

**Topic covered:** OpenBao architecture and security model

## What you will learn

- What OpenBao is, where it comes from, and which parts handle a request.
- How the barrier, the keyring, the root key and the unseal key protect stored data.
- How Shamir's secret sharing splits the unseal key into shares with a threshold.
- What a sealed, an unsealed and an uninitialized server answer, and how `sys/health` reports each state.
- How to unseal a server with the `bao` command-line tool and follow the progress.
- How secrets engines and auth methods are mounted at paths.
- Which seal types exist, what recovery keys do, and how a seal migration works.
- How a Raft cluster elects an active node, and how to save and restore a snapshot.

## The learning path

The section has three modules. Each has a landing page, short parts, a graded lab right after the part it tests, and a summary. The module's playground starts from its landing page.

### 1. Understand How OpenBao Protects Data

The playground holds an OpenBao server that is initialized with five key shares and a threshold of three, and then sealed.

1. What OpenBao Is And How A Request Travels
2. The Barrier, The Root Key And Shamir's Secret Sharing
3. Seal States And Health Checks, followed by the lab **Unseal A Server With A Key Threshold**
4. Mounts And Paths
5. Summary

### 2. Seals, High Availability And Backups

The playground holds a one-node server that is initialized and unsealed.

1. Seal Types And Auto-Unseal
2. Recovery Keys And Seal Migration
3. Raft Cluster And High Availability
4. Raft Snapshots, followed by the lab **Restore OpenBao From A Raft Snapshot**
5. Summary

### 3. Run A Three-Node OpenBao Cluster

The playground holds a three-node Raft cluster. The first node is unsealed and the other two are sealed.

1. Helm Values For A Raft Cluster
2. Joining And Unsealing The Nodes, followed by the lab **Turn A Single OpenBao Node Into A Three-Node Cluster**
3. Losing A Node
4. Autopilot And Maintenance
5. Summary

## Section capstone: Unseal A Server When One Key Share Is Wrong

The capstone is one graded scenario that uses everything in the section. A server is sealed, and one of its five key shares is wrong. You must unseal it without initializing it again, find out which share is wrong, and prove the server is healthy. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS112.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-112-capstone-010
```
