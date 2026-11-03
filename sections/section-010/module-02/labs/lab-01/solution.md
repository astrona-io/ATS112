# Solution: Restore OpenBao From A Raft Snapshot

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: `secret/inventory/db` is the original at version 1, `secret/inventory/extra` is gone, the cluster is the original one, and the pod is Ready and unsealed.

## Step 1: See the bad state

Sign in with the lab's root token and read the two secrets:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
bao kv get secret/inventory/db
bao kv get secret/inventory/extra
```

The first command shows the wrong password at version 2. The second shows a secret that should not exist.

## Step 2: Get the snapshot file

The snapshot is stored base64-encoded in the Secret. The dot in the key name must be escaped in the JSONPath:

```sh
kubectl -n openbao get secret pre-change-snapshot -o jsonpath='{.data.pre-change\.snap}' | base64 -d > pre-change.snap
ls -l pre-change.snap
```

The file has a size above zero.

## Step 3: Restore

```sh
bao operator raft snapshot restore pre-change.snap
```

The command replaces all the data of the cluster with the content of the file. The snapshot comes from this same cluster, so the command needs no `-force`.

## Step 4: Check the result

The restore can interrupt the port-forward. If a command cannot connect, start the port-forward again. If `bao status` shows `Sealed` `true`, unseal with the key from `openbao-init`:

```sh
bao status
bao operator unseal "$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.unseal-key}' | base64 -d)"
bao kv get secret/inventory/db
bao kv get secret/inventory/extra
```

The first read shows the original password and version 1. The second read reports that no value exists at the path. Send the lab for grading:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Write the old password back with `bao kv put` | The secret is at version 3, not 1, and `secret/inventory/extra` still exists |
| Delete `secret/inventory/extra` with `bao kv delete` | The entry is only marked deleted; its metadata remains and the grader sees it |
| Initialize the server again | A new, empty cluster has a new cluster ID, and the data is gone |

## Common mistakes

- Forgetting the base64 decoding of the Secret value, which gives a file the restore rejects.
- Forgetting to escape the dot in `pre-change\.snap`, which gives an empty result.
- Leaving the server sealed after the restore.
