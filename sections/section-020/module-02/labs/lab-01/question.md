# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Server settings, logging and telemetry

## Scenario

The platform team runs an OpenBao server for the inventory team with the default settings. The monitoring team wants to scrape its metrics with Prometheus, and the operators need more detail in the log while they investigate a slow start. The security team also wants shorter lease limits than the defaults.

The server was installed with Helm: release `openbao`, chart `openbao/openbao` version `0.30.4`, namespace `openbao`. It holds the secret `secret/inventory/db`. For this lab only, the unseal key and the root token are in the Secret `openbao-init` (keys `unseal-key` and `root-token`).

Reach the server with `kubectl -n openbao port-forward svc/openbao 8200:8200` in a second terminal and `export BAO_ADDR=http://openbao.localtest.me:8200`.

## Your task

1. Set the log level to `debug`.
2. Set the default lease TTL to `2h` and the maximum lease TTL to `48h`.
3. Turn on telemetry for Prometheus with `prometheus_retention_time` set to `30s`.
4. Let a scraper read `/v1/sys/metrics?format=prometheus` **without a token**, on the existing listener.
5. Make the running server use the new configuration, and bring it back into service.

## Constraints

- **Do not initialize the server again.** Its data and keys still exist.
- Change the configuration with `helm upgrade`, not by editing the ConfigMap.
- Keep the Raft storage, the listener on port `8200` and the rest of the configuration as it was.

## Done when

- The configuration sets `log_level = "debug"`, `default_lease_ttl = "2h"` and `max_lease_ttl = "48h"`.
- The configuration has a `telemetry` block with `prometheus_retention_time`, and the listener has `unauthenticated_metrics_access = true`.
- A request to `/v1/sys/metrics?format=prometheus` without a token answers `200`.
- The log of the running pod holds debug lines.
- The pod `openbao-0` is Ready, the server is unsealed and it is the original cluster, with `secret/inventory/db` readable.
