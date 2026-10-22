# Overview: Configure An OpenBao Server (Playground)

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

Paste these once in each new terminal. `show_config` prints the configuration the chart gave the server, `restart_openbao` deletes the pod and waits until it runs again, and `unseal_openbao` unseals it with the lab's key.

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
show_config() {
  kubectl -n openbao get configmap openbao-config -o jsonpath='{.data.extraconfig-from-values\.hcl}'
}
restart_openbao() {
  kubectl -n openbao delete pod openbao-0
  kubectl -n openbao wait --for=jsonpath='{.status.containerStatuses[0].started}'=true pod/openbao-0 --timeout=180s
}
unseal_openbao() {
  bao operator unseal "$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.unseal-key}' | base64 -d)"
}
```

Use them like this: `show_config`, `restart_openbao && unseal_openbao`.

## Practice tasks

- Save the values with `helm get values openbao -n openbao > my-values.yaml`, set `log_level = "warn"` in the configuration, apply it with `helm upgrade openbao openbao/openbao --version 0.30.4 -n openbao -f my-values.yaml`, and check that nothing changes until you run `restart_openbao`.
- Add a line `disable_mlock = true`, restart, and read what `kubectl -n openbao logs openbao-0` says about it.
- Run `kubectl -n openbao exec openbao-0 -- bao operator validate-config -config=/tmp/storageconfig.hcl` after each change.
- Change the storage `path` to `/openbao/data/other`, restart, and run `bao status`. Then change it back and restart. Note what happened to your data in between.
- Run `kubectl -n openbao exec openbao-0 -- env | grep BAO_` and match each variable to a setting in the configuration.
