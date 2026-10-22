# Overview: Initialize, Unseal And Operate OpenBao (Playground)

This is a **playground**, not a lab. It starts a fresh cluster and installs OpenBao, but does **not** initialize it: that is yours to do. There is no task, no `astrona submit` and no pass or fail. Initialize, seal, rotate, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao`: the pod `openbao-0` and the Service `openbao` on port `8200`. It is **not initialized**, so the pod shows `0/1`.
- The **`bao` command-line tool 2.7.1** on your machine. You also need `jq`.
- A `tester` pod in the namespace `clients` with `curl` and `jq`.

Start the port-forward in a second terminal and keep it running:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

## Helpers

Paste these once in each new terminal, after you have initialized the server into `init.json`. `share_from_init` prints one share from that file, and `use_init_root_token` puts its root token in `BAO_TOKEN`.

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
share_from_init() { jq -r ".unseal_keys_b64[$1]" init.json; }
use_init_root_token() { export BAO_TOKEN="$(jq -r '.root_token' init.json)"; }
```

Use them like this: `bao operator unseal "$(share_from_init 0)"`, `use_init_root_token`.

## Practice tasks

- Run `bao operator init -status` before and after initializing, and print `$?` each time.
- Initialize with `bao operator init -key-shares=5 -key-threshold=3 -format=json > init.json`, then unseal with shares 4, 0 and 2.
- Enable `kv-v2` at `secret/`, write `secret/app/config` twice with different values, and read both versions with `bao kv get -version=1 secret/app/config`.
- Seal the server, try to read a secret, and unseal it again.
- Run `bao operator key-status`, then `bao operator rotate`, then `key-status` again.
- Rotate the unseal keys to 3 shares with a threshold of 2 with `bao operator rotate-keys`, then restart the pod and unseal it with the new shares.
