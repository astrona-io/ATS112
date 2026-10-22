# The Server Configuration File

Before you can repair or design a server, you have to read its configuration. OpenBao uses HCL, the HashiCorp Configuration Language: blocks with a type and a body in braces, and settings written as `name = value`. This part reads a real configuration, the one your playground runs with, block by block.

## A complete configuration

Your playground's server runs with this configuration. Print it from the ConfigMap the Helm chart created:

<!-- astrona:playground:renew -->

```sh
kubectl -n openbao get configmap openbao-config -o jsonpath='{.data.extraconfig-from-values\.hcl}'
```

The output is the configuration below, written as HCL:

```hcl
ui = true

listener "tcp" {
  tls_disable     = 1
  address         = "[::]:8200"
  cluster_address = "[::]:8201"
}

storage "raft" {
  path    = "/openbao/data"
  node_id = "openbao-0"
}

api_addr     = "http://openbao.localtest.me:8200"
cluster_addr = "http://openbao-0.openbao-internal:8201"
```

It has two blocks and three top-level settings. The next sections explain each one.

## The listener

A **listener** is where OpenBao accepts requests. The block `listener "tcp"` opens a TCP (Transmission Control Protocol) port. `address = "[::]:8200"` means "every network interface, port 8200"; `[::]` is the IPv6 way to write "all addresses", and it includes IPv4. Clients send their API requests to this port.

`cluster_address = "[::]:8201"` is a second port for traffic between OpenBao servers in a cluster, such as request forwarding and Raft replication. `tls_disable = 1` turns TLS (Transport Layer Security) off. That is acceptable only in a lab: a real server always has `tls_cert_file` and `tls_key_file` in its listener, so that tokens and secrets never travel in clear text.

## The storage

The `storage` block says where OpenBao keeps its encrypted data. `storage "raft"` selects **Integrated Storage**, which uses the Raft consensus protocol to keep several servers in step. With one server, Raft simply stores the data in a folder.

`path` is that folder, here `/openbao/data`, which the chart mounts from a PersistentVolumeClaim, so the data survives a pod restart. `node_id` names this server in the Raft cluster. Both can also come from the environment variables `BAO_RAFT_PATH` and `BAO_RAFT_NODE_ID`.

The `path` is the most dangerous line in the file. If it points at a different folder, OpenBao does not complain: it finds an empty storage, starts as a server that is **not initialized**, and every secret seems to be gone. The data is still in the old folder; the server simply looks somewhere else.

## Addresses and other settings

Two settings tell others how to reach this server:

- `api_addr` is the full URL clients should use for this server, for example when a standby server redirects a client to the active one. It can also come from the environment variable `BAO_API_ADDR`.
- `cluster_addr` is the URL other servers use for the cluster port. It can also come from `BAO_CLUSTER_ADDR`. OpenBao always uses TLS between cluster members, whatever scheme the URL shows.

A few other top-level settings come up often. `ui = true` turns on the built-in web user interface at `/ui`. `log_level` sets how much the server logs; the default is `info`, and `warn` or `error` log less. `cluster_name` names the cluster in logs and metrics.

One setting you may find in old guides no longer exists: `disable_mlock`. HashiCorp Vault used memory locking to keep keys out of swap space. OpenBao removed that feature, so the setting is obsolete and only produces a message telling you to remove it.

Settings for the seal, telemetry and audit go in their own blocks. This course uses the default Shamir seal, which needs no `seal` block; an auto-unseal setup adds one, for example `seal "transit"`.

## Checking a configuration

OpenBao can check a configuration file without starting a server. `bao operator validate-config` reads the file and reports errors in its syntax and settings. Run it inside the pod, against the file the server started with:

```sh
kubectl -n openbao exec openbao-0 -- bao operator validate-config -config=/tmp/storageconfig.hcl
```

The command reports that the configuration is valid. It checks only the file: it does not check that the storage folder is writable or that the port is free. For a server that does not start, `bao operator diagnose` checks the running system too.

You can now read every line of a server configuration and check it. The open question is where the file in the pod comes from, and how a change reaches a running server.

## Common pitfalls

> [!WARNING]
> - **Changing the storage `path`.** OpenBao starts on the new folder as an uninitialized server. Never initialize it "to fix" that; point the path back at the real data.
> - **Running without TLS outside a lab.** `tls_disable = 1` sends tokens and secrets in clear text.
> - **Copying `disable_mlock` from a Vault guide.** OpenBao removed memory locking; delete the line.
