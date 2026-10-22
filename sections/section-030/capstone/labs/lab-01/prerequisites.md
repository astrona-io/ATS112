# Prerequisites

Before starting this lab you should be able to:

- Use `kubectl` to read Pods, Secrets and logs.
- Run the `bao` command-line tool against a server set with `BAO_ADDR`.
- Explain what sealed, unsealed and initialized mean for an OpenBao server.

## What the environment gives you

The environment builds itself before the task begins. It takes a few minutes:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao`, installed with the `openbao`
  Helm chart 0.30.4: one pod, `openbao-0`, and the Service `openbao` on port
  `8200`. The listener has no TLS, which is acceptable only in a lab.
- **Helm 3.22.1** and the **`bao` command-line tool 2.7.1** in
  `/usr/local/bin` or `~/.local/bin` on your machine.
- OpenBao answers at `http://openbao.localtest.me:8200` inside the cluster. On
  your machine, run `kubectl -n openbao port-forward svc/openbao 8200:8200` in
  a second terminal and `export BAO_ADDR=http://openbao.localtest.me:8200`. If
  the name does not resolve, add `127.0.0.1 openbao.localtest.me` to
  `/etc/hosts`.

## Working rules

- Everything is graded on the **final state**, so check your result at the end
  and leave it in place.
- Any key shares or tokens the environment gives you in Kubernetes Secrets are
  lab-only. A real installation never keeps them in the cluster it protects.
- A restart of `openbao-0` seals OpenBao again. Unseal it after every restart.
