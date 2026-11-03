# Server-Wide Settings

The listener and the storage describe where the server lives. A third group of settings, written at the top level of the file, describes how it behaves: how long tokens and secrets live, whether the web interface is on, and how the process treats memory and logs. This part goes through the ones you will set on almost every server.

## Lease times

A **lease** is a time limit that OpenBao attaches to a token or to a dynamically created secret. When the lease ends, the token or secret stops working. Two settings control the limits for the whole server:

```hcl
default_lease_ttl = "2h"
max_lease_ttl     = "48h"
```

`default_lease_ttl` is the time to live (TTL) given when a client does not ask for one. `max_lease_ttl` is the longest TTL any client may get or renew to. Without these lines, the defaults are 768 hours (32 days) for both values. Each mount can override them with `bao secrets tune`, and a token can ask for a shorter time, but never for a longer one than the maximum of its mount.

Short leases limit the damage of a leaked token, and they cost more renewals. A value of a few hours for the default and a day or two for the maximum is common for application tokens.

## The user interface and the cluster name

`ui = true` turns on the built-in web interface at the path `/ui/` of the API address. Without it, a request to that path fails. The interface uses the same API and the same tokens as the command line, so enabling it does not add a new way in; it does add a new thing to protect behind TLS.

`cluster_name` gives the cluster a readable name. If you leave it out, OpenBao generates one. The name appears in `bao status` as `Cluster Name`, and in metrics and logs.

## Memory locking

An operating system can write a process's memory to disk (swap) when memory is short. In HashiCorp Vault, the setting `disable_mlock` controlled whether the server asked the operating system to keep its memory in RAM with the `mlock` call, so that the root key and the keyring never reached swap.

OpenBao removed memory locking. The setting `disable_mlock` is obsolete: a configuration that still has it produces a message telling you to remove it. This changes what protects the keys in memory. Turn swap off on the machine, which is the normal state of Kubernetes nodes, or use encrypted swap. If you copy a configuration from a Vault guide, delete the line.

## Logging

Two settings shape the server's log, which the pod writes to standard output:

- `log_level` is `trace`, `debug`, `info`, `warn` or `error`. The default is `info`. `debug` shows what the server does for each request path and is useful for a short investigation; it is noisy and slows busy servers.
- `log_format` is `standard` for plain lines or `json` for one JSON object per line. Use `json` when a log collector parses the output.

```hcl
log_level  = "info"
log_format = "json"
```

You can see both settings, with the rest of the running configuration, on the playground:

<!-- astrona:playground:renew -->

```sh
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
bao read sys/config/state/sanitized
kubectl -n openbao logs openbao-0 --tail=5
```

The first command shows the loaded configuration, and the second shows the last lines of the log. The playground configuration sets `ui` and leaves the log level at the default.

Change these settings the way you change every other one: edit the Helm values, run `helm upgrade`, delete the pod and unseal.

You can now set the top-level behavior of a server. The next part turns to its network side: the listener and what it must do to protect the connection.

## Common pitfalls

> [!WARNING]
> - **Setting `max_lease_ttl` lower than `default_lease_ttl`.** The default cannot exceed the maximum, so the server rejects or caps the value.
> - **Copying `disable_mlock` from a Vault guide.** OpenBao removed memory locking; delete the line, and keep swap off on the nodes.
> - **Leaving `log_level = "debug"` in production.** It writes far more data, and may include request details.
