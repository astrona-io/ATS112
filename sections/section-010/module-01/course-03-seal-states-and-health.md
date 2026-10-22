# Seal States And Health Checks

Load balancers, Kubernetes probes and monitoring systems must know whether an OpenBao server can serve requests. They cannot run `bao status` and read a table. This part shows the two API endpoints they use, what each state looks like, and how to move a server from sealed to unsealed while you watch the progress.

## Three states

A server is always in one of three states, and the API reports each one differently:

| State | What it means |
| --- | --- |
| Not initialized | The storage is empty; no keys exist yet. Only initialization is possible |
| Initialized, sealed | Keys exist in storage, but the server holds none in memory. Only unsealing is possible |
| Initialized, unsealed | The server holds its keys in memory and serves requests |

The endpoint `/v1/sys/seal-status` reports the state as JSON (JavaScript Object Notation), and it never needs a token. Ask it from your machine with `curl`:

<!-- astrona:playground:renew -->

```sh
curl -s $BAO_ADDR/v1/sys/seal-status
```

The response has the fields `initialized` (`true`), `sealed` (`true`), `t` (the threshold, `3`), `n` (the number of shares, `5`) and `progress` (`0`, the number of shares entered so far). It also names the seal `type`, `shamir`, and the `storage_type`, `raft`.

## The health endpoint

The endpoint `/v1/sys/health` answers the same question with an HTTP status code, which is what probes and load balancers read. By default it returns:

| Status code | Meaning |
| --- | --- |
| `200` | Initialized, unsealed and active |
| `429` | Unsealed and standby (in a cluster with several servers) |
| `501` | Not initialized |
| `503` | Sealed |

Ask it for the status code only:

```sh
curl -s -o /dev/null -w '%{http_code}\n' $BAO_ADDR/v1/sys/health
```

Your sealed server answers `503`. The Helm chart's readiness probe does not use this endpoint; it runs `bao status` inside the pod, which fails while the server is sealed. That is why `openbao-0` shows `0/1` now.

## Unsealing and following the progress

Unsealing means entering shares until the threshold is reached. Each `bao operator unseal` call enters one share, and the server remembers the progress between calls, even when the shares come from different machines. Read the first share from the lab's Secret and enter it:

```sh
SHARE_1="$(kubectl -n openbao get secret openbao-shares -o jsonpath='{.data.share-1}' | base64 -d)"
bao operator unseal "$SHARE_1"
```

The table now shows `Sealed` still `true` and `Unseal Progress` `1/3`. Enter two more shares, for example the third and the fifth; the order does not matter:

```sh
bao operator unseal "$(kubectl -n openbao get secret openbao-shares -o jsonpath='{.data.share-3}' | base64 -d)"
bao operator unseal "$(kubectl -n openbao get secret openbao-shares -o jsonpath='{.data.share-5}' | base64 -d)"
```

After the third share, `Sealed` is `false` and the progress is back to `0`. The health endpoint now answers `200`, and within a few seconds the pod becomes `1/1`. If you entered a share by mistake, `bao operator unseal -reset` throws away the shares entered so far and starts the count again.

Now the secret is readable. Sign in with the lab's root token and read it:

```sh
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-root -o jsonpath='{.data.root-token}' | base64 -d)"
bao kv get secret/inventory/db
```

The output shows the fields `username` and `password` of the secret. The same data was on disk all along; only the keys in memory changed.

You can now read the state of a server through the API, read its health as a status code, and unseal it with a threshold of shares. That is the core skill of operating OpenBao, and the next step is to prove you can do it on your own.

## Common pitfalls

> [!WARNING]
> - **Probing `/v1/sys/health` and expecting only 200.** A sealed server answers `503` and an uninitialized one `501` on purpose. Read the code, do not treat it as an error.
> - **Mixing shares from two attempts.** Progress is kept on the server. If you are unsure what you entered, run `bao operator unseal -reset` and start again.
> - **Initializing a server again because it is sealed.** A sealed server already has its keys and data. Initializing it is not possible while it is initialized, and on a new storage it would start with no data at all.

## Your mission: Unseal A Server With A Key Threshold

You can now read a server's state and unseal it with enough key shares. The graded lab gives you a sealed server with five shares and a threshold of three, and asks you to unseal it, read a secret it holds, and prove you read it.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-112-playground-010-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS112.git -c sections/section-010/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-112-lab-010-01
astrona start ats-112-playground-010-01
```
