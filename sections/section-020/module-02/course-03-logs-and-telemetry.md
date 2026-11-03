# Logs And Telemetry Metrics

An operator learns about a server from two streams. The log says what happened, in order. The metrics say how much and how fast, as numbers that a monitoring system collects every few seconds. This part shows the OpenBao settings for both, and how to let a monitoring system read the metrics without handing it a token.

## The log

OpenBao writes its log to standard output, and in Kubernetes the container runtime keeps that output. You read it with `kubectl logs`. The log level and format come from `log_level` and `log_format`. Look at what your playground server logs:

<!-- astrona:playground:renew -->

```sh
kubectl -n openbao logs openbao-0 --tail=10
```

The lines hold a timestamp, a level in brackets, a component name and a message, such as the seal and the storage coming up at start. The log does not hold secrets or request bodies. The record of who read which secret is a separate stream, the audit log, which has its own devices.

## Telemetry

**Telemetry** is the set of numbers that OpenBao counts about itself: requests per second, how long requests take, how many tokens exist, how Raft is doing, and more. A `telemetry` block at the top level of the configuration chooses where to send them:

```hcl
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname          = true
}
```

OpenBao can push metrics to systems such as StatsD, but the usual way in Kubernetes is Prometheus, which pulls them. `prometheus_retention_time` is how long OpenBao keeps the values for a pull; with `0` it turns the Prometheus output off, and the default is 24 hours. `disable_hostname` removes the host name from the metric names, which keeps the names the same when pods are replaced.

## The metrics endpoint

The metrics are served by the system backend at `sys/metrics`. The format `prometheus` asks for the text format that Prometheus reads:

```sh
curl -s -H "X-Vault-Token: $BAO_TOKEN" "$BAO_ADDR/v1/sys/metrics?format=prometheus"
```

On the playground the server has the Prometheus output on by default. The request needs a token, and the answer has one line per metric with its name and its value. Without the token header, the same request returns `403` (permission denied).

A Prometheus server that scrapes every 15 seconds would then need a token. A token has a lease, so it expires and the scrape stops. To avoid this, the listener can allow reading the metrics without a token:

```hcl
listener "tcp" {
  address         = "[::]:8200"
  tls_disable     = 1
  telemetry {
    unauthenticated_metrics_access = true
  }
}
```

The setting belongs inside the listener block, in its own `telemetry` block, and not in the top-level one. It opens only the metrics path for that listener. It does not open any secret. Metrics still show names of mounts and counts of requests, so give this listener to a monitoring network and not to the internet. The safer alternative is a policy that allows only `read` on `sys/metrics` and a token created with it, and renewed by the scraper.

## Applying the settings

Both blocks are read at start. In the Helm chart, you add them to `server.standalone.config`, run `helm upgrade`, delete the pod and unseal the server with the key share. After the restart, the unauthenticated request works:

```sh
curl -s -o /dev/null -w '%{http_code}\n' "$BAO_ADDR/v1/sys/metrics?format=prometheus"
```

It prints `200` once the setting is live and `403` before. This is a convenient test, because it proves that the new configuration is the one that runs.

A few metrics to know by name: `vault_core_unsealed` is `1` when the server is unsealed, `vault_core_active` is `1` on the active node, and `vault_raft_apply` times the writes to storage. The names start with `vault_` for compatibility with existing dashboards, even in OpenBao.

You can now make a server tell you what it is doing. The graded lab asks you to turn on debug logging, Prometheus metrics for a scraper without a token, and new lease limits, on a server that must keep its data.

## Common pitfalls

> [!WARNING]
> - **Putting `unauthenticated_metrics_access` in the top-level `telemetry` block.** It belongs in the `telemetry` block inside the `listener`.
> - **Setting `prometheus_retention_time = "0"`.** That turns the Prometheus output off.
> - **Expecting the audit trail in the server log.** The log does not record who read a secret.

## Your mission: Enable Metrics And Debug Logging

You can now read the log, add telemetry settings and open the metrics path for a scraper. The graded lab gives you a running server with its default configuration. You must add the settings through Helm, restart the pod, unseal it, and keep the data.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-112-playground-020-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS112.git -c sections/section-020/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-112-lab-020-02
astrona start ats-112-playground-020-02
```
