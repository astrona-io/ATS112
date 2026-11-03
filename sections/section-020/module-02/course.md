# Secure And Observe An OpenBao Server

A server that works is not yet a server you can run. Clients must reach it over an encrypted connection, its logs must say what happens, and a monitoring system must be able to read its metrics. All of this is set in the same configuration file that sets the listener and the storage.

Keep one sentence in mind: **the configuration file decides how the server talks to the network and what it reports about itself, and the server reads it once, at start.**

The module has four parts. **Server-Wide Settings** covers the top-level settings such as lease times, the user interface and memory locking. **Listener TLS And Client Certificates** turns on encrypted connections and shows how clients check them. **Logs And Telemetry Metrics** sets the log level and format, enables the Prometheus metrics endpoint and controls who may read it; a graded lab follows it. **Checking What The Server Really Runs** shows how to compare the file with the running server and how to read startup errors.

## Learning objectives

After this module you can:

- Set `default_lease_ttl`, `max_lease_ttl`, `ui`, `log_level` and `log_format`, and explain why `disable_mlock` is obsolete.
- Write a `listener "tcp"` block with TLS, a minimum TLS version and client certificate checks.
- Point `bao` at a server with a private certificate authority with `BAO_CACERT`.
- Enable Prometheus metrics, and decide whether the metrics endpoint needs a token.
- Compare a configuration file with the running server with `bao read sys/config/state/sanitized`.
- Read the log of a server that fails to start.

## Before you start

You need the configuration blocks of a standalone server (listener, storage, `api_addr`) and how the Helm chart applies values and restarts the pod. You should know that a changed configuration needs a pod restart and an unseal.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, installed with the `openbao` Helm chart 0.30.4. The server is initialized with a single key share and unsealed. For this lab only, the unseal key and the root token are in the Kubernetes Secret `openbao-init` (keys `unseal-key` and `root-token`); a real installation never keeps them in the cluster.

The environment installs Helm and the `bao` command-line tool on your machine. Start the port-forward in a second terminal (`kubectl -n openbao port-forward svc/openbao 8200:8200`) and set `export BAO_ADDR=http://openbao.localtest.me:8200`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
