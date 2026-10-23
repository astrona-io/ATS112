# Development Mode Against A Real Server

Tutorials often start OpenBao with one command and no configuration file at all. That is development mode, and it is useful for a quick test. It is also the most common way a test setup ends up holding real data. This part shows what development mode does, so you recognise it and never run real work on it.

## What development mode does

The command `bao server -dev` starts a server in development mode. It needs no configuration file. It keeps all data **in memory**, it is **already initialized and unsealed**, and it creates a root token at once; `-dev-root-token-id` sets that token to a value you choose. By default it listens without TLS on `127.0.0.1:8200`. The Helm chart has the same mode behind the value `server.dev.enabled`.

The convenience is exactly the danger:

| Development mode | A real server |
| --- | --- |
| Data in memory, lost on every restart | Data in a storage backend, kept across restarts |
| Starts unsealed; no key shares exist | Starts sealed; unsealing needs key shares or auto-unseal |
| Root token known in advance | Root token created once at initialization, then revoked |
| No configuration file | A configuration file with listener, storage and addresses |

## Seeing the difference from outside

The seal status shows which kind of server you talk to. Compare your playground's real server with what a development server reports:

<!-- astrona:playground:renew -->

```sh
curl -s $BAO_ADDR/v1/sys/seal-status
```

Your playground reports `storage_type` `raft` and `n` `1`, the single key share it was initialized with. A development server reports `storage_type` `inmem`, because it stores everything in memory. If you ever see `inmem` on a server that applications use, every secret on it disappears at the next restart.

## Moving from development mode to a real server

Moving to a real server is not a setting you switch on. A development server's data lives in its memory, so nothing carries over: you write a real configuration, start the server with it, initialize it, unseal it, and recreate what you need. In Helm terms, that means values with `server.dev.enabled: false` (the default) and `server.standalone.config` with a full configuration, then a pod restart, then `bao operator init`.

That is the work of the section capstone. The checklist it follows is short:

1. A `listener "tcp"` block on `[::]:8200` (with TLS on a real server).
2. A `storage "raft"` block with a `path` on persistent storage and a `node_id`.
3. `api_addr` with the address clients use.
4. Any extra settings you need, such as `ui` and `log_level`.
5. Delete the StatefulSet with `kubectl -n openbao delete statefulset openbao --cascade=orphan` (the data volume changes its `volumeClaimTemplates`, which Kubernetes never updates in place), then `helm upgrade`, delete the pod, initialize, unseal, and store your first secret.

You now know what development mode is, how to recognise it from the seal status, and what moving to a real server involves. With the configuration file, the chart's path and the difference between both modes, you have what you need to run a server you can trust.

## Common pitfalls

> [!WARNING]
> - **Using development mode "only for now".** Its data is gone at the next restart, and its root token is often written in scripts and chat messages.
> - **Expecting data to survive the move.** A development server keeps nothing on disk. Recreate secrets on the real server.
> - **Forgetting the pod restart.** The chart uses `OnDelete`; after `helm upgrade`, delete `openbao-0`.
> - **Running `helm upgrade` straight from development mode.** It stops with `spec.volumeClaimTemplates: ... field is immutable`. Delete the StatefulSet with `--cascade=orphan` first; Helm creates a new one.
