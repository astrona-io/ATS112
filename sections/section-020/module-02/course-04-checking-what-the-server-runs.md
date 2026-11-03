# Checking What The Server Really Runs

A configuration file is only a plan. What counts is what the running process loaded. When a server behaves in a way the file does not explain, or when it does not start at all, you need ways to check the file before the restart, compare it with the server afterwards, and read the reason for a failure. This part gives you those three steps.

## Before the restart: validate and diagnose

Two commands read a configuration file and report problems without starting a server. `bao operator validate-config` checks that the file parses and that the blocks and settings are known. `bao operator diagnose` goes further: it runs checks on the machine that would run the server, such as whether the storage path is writable, whether the certificate files exist and match, and whether the listener address is free. The chart writes the configuration the server started with to `/tmp/storageconfig.hcl` inside the pod. Check it there:

<!-- astrona:playground:renew -->

```sh
kubectl -n openbao exec openbao-0 -- bao operator validate-config -config=/tmp/storageconfig.hcl
```

A valid file produces no error. `bao operator diagnose -config=<file>` takes the same option. Run it on a stopped server or on a copy of its environment, because one of its checks is that the listener address is free, and a running server already uses it.

A check before the restart is cheap. A wrong file costs a restart, an unseal and, for a node in a cluster, a period without that node.

## After the restart: compare

When a server runs, ask it for the configuration it loaded:

```sh
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
bao read sys/config/state/sanitized
```

The answer lists the values from the file: the listeners, the storage type, the telemetry and the top-level settings. It leaves out secrets, such as the keys in the seal configuration. If a value you changed is missing here, the server did not read your change, and the cause is outside OpenBao: the pod was not restarted, the ConfigMap was not updated, or another file or an environment variable overrides it.

The `bao status` output gives a second view of some facts: `Storage Type`, `Cluster Name`, `Version` and the HA state.

## When the server does not start

If the file is wrong, the process exits and Kubernetes restarts the container again and again. The pod shows `CrashLoopBackOff` or a restart count that rises. Read the log of the failed run, not of the new one:

```sh
kubectl -n openbao logs openbao-0 --previous
kubectl -n openbao describe pod openbao-0
```

`--previous` prints the log of the last container that exited. The last lines carry the reason. Typical causes are:

- An error that says the configuration could not be parsed or contains an unknown key. Compare the file with `validate-config`.
- A storage path that is not writable, or a data volume owned by another user.
- A listener address that is already in use, for example when two listeners ask for port `8200`.
- A certificate or key file that does not exist at the given path.

A subtler failure is a server that starts fine on the wrong data. A wrong storage `path` makes a new, empty storage with a new cluster ID. The server then reports `Initialized` `false`, and the real data is still in the old folder. Compare the cluster ID with the one you recorded before the change.

You can now check a configuration at three moments: before the restart, after it, and when it fails. Together with the settings of the earlier parts, this is the full set of steps for changing the configuration of a server safely.

## Common pitfalls

> [!WARNING]
> - **Reading the log of the new container after a crash.** Use `--previous` for the failed one.
> - **Trusting the file instead of the running server.** Always read the loaded configuration after a change.
> - **Running `bao operator init` on a server that says `Initialized` `false` after a change.** That may be a wrong data path, not a new server.
