# Overview: Run A Three-Node OpenBao Cluster (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao with the `openbao` Helm chart, initializes the first node with one key share and unseals it. There is no task, no `astrona submit` and no pass or fail. Change the configuration, break it, `astrona destroy`, start over.

## What's in the box

- A `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao`, Helm release `openbao`, chart 0.30.4: a three-node Raft cluster: the pods `openbao-0`, `openbao-1` and `openbao-2`, and the Service `openbao` on port `8200`. The first node is initialized and **unsealed**. The two other nodes have joined the cluster and are **sealed**; unsealing them is part of the practice.
- **Helm 3.22.1** and the **`bao` command-line tool 2.7.1** on your machine.
- The Secret `openbao-init` with the lab-only unseal key (`unseal-key`) and root token (`root-token`).
- A `tester` pod in the namespace `clients` with `curl` and `jq`.

Start the port-forward in a second terminal and keep it running:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

## Helpers

Paste these once in each new terminal:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
export UNSEAL="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.unseal-key}' | base64 -d)"
```

## Practice tasks

- Run `bao operator raft list-peers` and `kubectl -n openbao get pods -L openbao-active`. Find the leader and the two followers.
- Check each pod with `kubectl -n openbao exec openbao-1 -- bao status`. Compare `HA Mode` on the three pods.
- Delete a follower pod, repeat `bao operator raft list-peers`, and unseal the new pod with `kubectl -n openbao exec openbao-1 -- bao operator unseal "$UNSEAL"`.
- Delete the leader pod and watch the election. You may need to restart the port-forward after the pod is deleted.
- Delete two pods at once and read the error of `bao operator raft list-peers`. Unseal them again.
- Run `bao operator raft autopilot state` and `bao operator raft autopilot get-config`.
- Write a secret, run `bao operator raft snapshot save backup.snap`, and read the file size.
