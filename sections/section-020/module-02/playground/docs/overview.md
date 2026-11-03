# Overview: Secure And Observe An OpenBao Server (Playground)

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
restart_openbao() {
  kubectl -n openbao delete pod openbao-0
  kubectl -n openbao wait --for=jsonpath='{.status.containerStatuses[0].started}'=true pod/openbao-0 --timeout=180s
}
unseal_openbao() {
  bao operator unseal "$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.unseal-key}' | base64 -d)"
}
```

## Practice tasks

- Request `$BAO_ADDR/v1/sys/metrics?format=prometheus` with and without the header `X-Vault-Token`, and compare the status codes.
- Save the values with `helm get values openbao -n openbao -o yaml > my-values.yaml`, add the telemetry settings from the reading, apply them with `helm upgrade openbao openbao/openbao --version 0.30.4 -n openbao -f my-values.yaml`, run `restart_openbao && unseal_openbao`, and repeat the request.
- Set `log_level = "trace"`, restart, and compare the amount of output of `kubectl -n openbao logs openbao-0` with the debug level.
- Run `kubectl -n openbao exec openbao-0 -- bao operator diagnose -config=/tmp/storageconfig.hcl` and read each check it reports.
- Read the running configuration with `bao read sys/config/state/sanitized` after each change.
