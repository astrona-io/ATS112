# Overview: Work With bao Daily (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao with the `openbao` Helm chart, initializes it with one key share and unseals it. There is no task, no `astrona submit` and no pass or fail. Change the configuration, break it, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao`, Helm release `openbao`, chart 0.30.4: the pod `openbao-0` and the Service `openbao` on port `8200`. It is initialized and **unsealed**.
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
```

## Practice tasks

- Enable the KV engine with `bao secrets enable -path=secret kv-v2`, write `secret/inventory/db`, and add `-output-curl-string` to the `bao kv get` to see the HTTP request.
- Read the same secret with `bao read secret/data/inventory/db` and list it with `bao list secret/metadata/inventory`.
- Write a policy with `bao policy write`, create a token with it, and test paths with `bao token capabilities`.
- Run `bao kv put -output-policy secret/inventory/db password=x` and read the rule it prints.
- Enable an audit device with `bao audit enable file file_path=stdout`, make a request, and read the entry with `kubectl -n openbao logs openbao-0`.
