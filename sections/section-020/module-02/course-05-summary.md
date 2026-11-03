# Summary

Top-level settings shape how a server behaves. `default_lease_ttl` and `max_lease_ttl` limit how long tokens and secrets live, `ui` turns on the web interface, `cluster_name` names the cluster, and `disable_mlock` is obsolete because OpenBao removed memory locking, so keep swap off on the nodes. `log_level` and `log_format` shape the log that the pod writes to standard output.

A listener protects the connection with `tls_cert_file`, `tls_key_file` and `tls_min_version`. The certificate must name the address clients use, and `api_addr` should be an `https://` address. `tls_client_ca_file` with `tls_require_and_verify_client_cert` requires clients to present a certificate. The `bao` tool trusts a private authority through `BAO_CACERT`; `BAO_SKIP_VERIFY` removes the check and is never a fix.

A `telemetry` block chooses where the server reports metrics. For Prometheus, `prometheus_retention_time` sets how long values are kept, and the endpoint `sys/metrics?format=prometheus` serves them. It needs a token unless the listener has a `telemetry` block with `unauthenticated_metrics_access = true`. The audit log, not the server log, records who read a secret.

A configuration is checked at three moments. `bao operator validate-config` and `bao operator diagnose` check the file before the restart. `bao read sys/config/state/sanitized` shows what the running server loaded. `kubectl logs --previous` shows why a container failed. A wrong storage path shows up as `Initialized` `false`, and does not mean the data is gone.

The key facts to remember:

- TLS on every real listener; `tls_disable` is for labs.
- `unauthenticated_metrics_access` goes inside the listener's `telemetry` block.
- Compare the file with the running server after every change.
- Read the previous container log after a crash.

<!-- astrona:playground:destroy -->
