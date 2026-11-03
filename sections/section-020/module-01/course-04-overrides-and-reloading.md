# Environment Variables, Several Files And Reloading

One configuration file is the simplest case. Real installations split the configuration over several files, let the platform fill in values that differ per pod, and sometimes change a setting without a restart. This part shows the ways to give OpenBao its configuration, which ones override others, and which changes need a restart.

## One file, a directory, or several files

The `bao server` command takes the option `-config` more than once, and each value can be a file or a directory. When you give it a directory, the server loads every file in it that ends in `.hcl` or `.json`, in alphabetical order, and merges them into one configuration. A file can hold HCL (HashiCorp Configuration Language) or JSON.

Keep each block in one file. A configuration has one `storage` block, so it must not appear in two files. Blocks that can repeat, such as `listener`, add up. Split files by topic, for example one file for the storage and one for the listeners, and not by environment.

This is why the Helm chart works. It writes your `server.standalone.config` text to its own file in the ConfigMap and starts the server with the option `-config` pointing at that file. A second file can sit next to it without a conflict, as long as it holds other blocks.

You can check which configuration the running server really uses. The system backend returns it with secrets removed, and it needs a token with the `sudo` capability, which the root token has. Use the lab's token:

<!-- astrona:playground:renew -->

```sh
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
bao read sys/config/state/sanitized
```

The output lists the listeners, the storage type, the telemetry settings and the other values the server loaded. When a change seems to have no effect, compare this output with the file you edited.

## Environment variables

Some values are set from the environment instead of the file. This keeps per-pod values out of the shared file. The ones to know have names that start with `BAO_`:

| Variable | Sets |
| --- | --- |
| `BAO_API_ADDR` | `api_addr`, the address clients use |
| `BAO_CLUSTER_ADDR` | `cluster_addr`, the address other nodes use |
| `BAO_RAFT_NODE_ID` | the `node_id` of the Raft storage |
| `BAO_LOG_LEVEL` | the log level |
| `BAO_LOCAL_CONFIG` | a complete configuration, in HCL or JSON, used by the container image |

When both exist, the environment variable wins over the same setting in the file. The Helm chart uses this for `api_addr` and `cluster_addr` on clusters, where each pod needs its own address.

Older names with a `VAULT_` prefix exist in other tools of the same family. Use the `BAO_` names in new work.

## What a restart is for

The server reads its configuration once, when it starts. A process that is already running keeps the values it read. For this reason a changed Helm value does nothing until the pod is replaced, because the process keeps the values it read.

OpenBao can reload a small set of settings without a restart when the server process receives the `SIGHUP` signal, which an administrator sends with `kill -HUP <process id>`. The reload covers the TLS certificate and key files of the listeners and the log level. Everything else, including the storage type, the listener addresses and the seal, needs a restart. Reloading the certificate files is the important case: a certificate that is renewed on disk can be taken into use without sealing the server.

In the chart, the OpenBao server is the main process of its container, so you can send the signal with `kubectl exec`. The command below uses process ID 1; it is safe on the playground, where nothing in the file changed, because a reload of an unchanged file does nothing:

```sh
kubectl -n openbao exec openbao-0 -- kill -HUP 1
kubectl -n openbao logs openbao-0 --tail=5
```

The log shows a line about the reload. The server stays unsealed through it, which you can confirm with `bao status`.

You can now choose how to give OpenBao its configuration and tell which changes need a restart.

## Common pitfalls

> [!WARNING]
> - **Expecting `SIGHUP` to apply a changed storage block or listener address.** Only certificates and the log level reload; the rest needs a restart.
> - **Repeating a block in two files.** Two `storage` blocks make the configuration invalid.
> - **Forgetting that an environment variable wins.** A value you edit in the file has no effect when a variable sets the same key.
