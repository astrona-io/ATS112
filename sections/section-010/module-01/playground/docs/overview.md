# Overview: Understand How OpenBao Protects Data (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao, initializes it with five key shares and a threshold of three, and seals it. There is no task, no `astrona submit` and no pass or fail. Explore, seal and unseal as often as you like, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao`: the pod `openbao-0` and the Service `openbao` on port `8200`. It is initialized and **sealed**, so the pod shows `0/1`.
- The **`bao` command-line tool 2.7.1** on your machine.
- The Secret `openbao-shares` with the five key shares (`share-1` to `share-5`) and the Secret `openbao-root` with the root token. Both are lab-only; a real installation never keeps them in the cluster.
- One secret, `secret/inventory/db`, written before the server was sealed.
- A `tester` pod in the namespace `clients` with `curl` and `jq`.

Start the port-forward in a second terminal and keep it running:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

## Helpers

Paste these once in each new terminal. `share` prints one key share from the lab's Secret, and `use_root_token` puts the lab's root token in `BAO_TOKEN`.

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
share() {
  kubectl -n openbao get secret openbao-shares -o jsonpath="{.data.share-$1}" | base64 -d
}
use_root_token() {
  export BAO_TOKEN="$(kubectl -n openbao get secret openbao-root -o jsonpath='{.data.root-token}' | base64 -d)"
}
```

Use them like this: `bao operator unseal "$(share 2)"`, `use_root_token`.

## Practice tasks

- Run `bao status` and `curl -s $BAO_ADDR/v1/sys/seal-status` and match every field of the JSON to a line of the table.
- Enter two shares, then check `progress`. Run `bao operator unseal -reset` and check it again.
- Unseal with shares 5, 1 and 4, in that order. Then seal with `use_root_token; bao operator seal` and unseal with another three.
- Ask `/v1/sys/health` for its status code while sealed and while unsealed. Then add `?sealedcode=200` to the URL and see what changes.
- Delete the pod with `kubectl -n openbao delete pod openbao-0` while the server is unsealed. Check the seal state when the new pod starts.
