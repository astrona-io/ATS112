# Understand How OpenBao Protects Data

An OpenBao server keeps passwords, keys and certificates for many applications. Its storage therefore holds the most valuable data in the company. Yet if you copy that storage, you get nothing you can read: OpenBao encrypts every byte before it writes it, and keeps the key only in memory.

This module explains how that works and how you operate it. Keep one sentence in mind: **a sealed OpenBao has its data but not the key to read it, and unsealing gives it that key.** Everything else in the module follows from that sentence.

The module has three parts. **What OpenBao Is And How A Request Travels** introduces the server and follows one request from the client to the storage. **The Barrier, The Root Key And Shamir's Secret Sharing** opens the layers of keys that protect the data and shows how the unseal key is split into shares. **Seal States And Health Checks** shows what a server answers in each state, and how to unseal it. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Explain what OpenBao is and name the parts that handle a request.
- Explain the barrier, the keyring, the root key and the unseal key, and how each protects the next.
- Explain Shamir's secret sharing with the words key share and threshold.
- Read `bao status` and `/v1/sys/seal-status`, and say whether a server is initialized and sealed.
- Read the status codes of `/v1/sys/health`.
- Unseal a server by entering enough key shares, and follow the progress.

## Before you start

You need Kubernetes basics: namespaces, pods, Secrets and the commands `kubectl get`, `kubectl logs` and `kubectl port-forward`. You do not need to know OpenBao yet.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`. The server runs as the pod `openbao-0` behind the Service `openbao` on port `8200`. It is already initialized with five key shares and a threshold of three, and it is **sealed**. For this lab only, the five key shares are in the Kubernetes Secret `openbao-shares` and the root token is in the Secret `openbao-root`; a real installation never keeps them in the cluster it protects.

The environment installs the `bao` command-line tool on your machine. Start the port-forward in a second terminal and keep it running:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

Then set the address in the terminal where you run commands: `export BAO_ADDR=http://openbao.localtest.me:8200`. The pod `openbao-0` shows `0/1` while the server is sealed; that is expected.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
