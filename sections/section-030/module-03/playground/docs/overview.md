# Overview: Authenticate Clients And Encrypt Data (Playground)

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

- Enable `userpass`, create a user with a policy, log in with `bao login -method=userpass username=...`, and compare `bao token lookup` before and after.
- Enable `approle`, create a role with `secret_id_num_uses=1`, log in twice with the same secret ID, and read the second error.
- Enable `kubernetes` with `bao auth enable kubernetes` and read `bao path-help auth/kubernetes/role/x` to see every role field.
- Enable `transit`, create a key, encrypt a value, rotate the key, decrypt the old ciphertext, and rewrap it.
- Run `bao auth list -detailed` and note the accessor of each method.
