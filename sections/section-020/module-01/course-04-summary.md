# Summary

An OpenBao server reads one configuration file, written in HCL, when it starts. The `listener "tcp"` block sets the address for API requests, here `[::]:8200`, and the cluster port `8201`; a real server always adds a TLS certificate and key there. The `storage "raft"` block selects Integrated Storage, with a `path` for the data folder and a `node_id`. `api_addr` and `cluster_addr` tell clients and other servers how to reach this one; the environment variables `BAO_API_ADDR` and `BAO_CLUSTER_ADDR` can set them too. `ui` turns on the web interface and `log_level` sets how much the server logs. `disable_mlock` is obsolete, because OpenBao removed memory locking.

The storage `path` deserves special care. Pointed at another folder, the server starts there as if it were new and uninitialized, and its data seems gone although it is untouched in the old folder. The fix is to point the path back, never to initialize again.

On Kubernetes, the Helm chart writes the value `server.standalone.config` into the ConfigMap `openbao-config`, and the container copies it to `/tmp/storageconfig.hcl` and starts `bao server` with it, after replacing placeholders such as `HOSTNAME`. The StatefulSet uses the `OnDelete` update strategy, so a change takes three steps: `helm upgrade`, deleting the pod, and unsealing the new pod. `bao operator validate-config` checks a file without starting a server.

Development mode, `bao server -dev` or the chart value `server.dev.enabled`, keeps data in memory, starts unsealed and creates a known root token. It reports `storage_type` `inmem`. Moving from it to a real server means a new configuration, a restart, initialization and recreating the data.

The key facts to remember:

- The configuration is read only at start.
- With the chart, a change needs `helm upgrade`, a pod deletion and an unseal.
- A wrong storage `path` looks like data loss; it is a wrong folder.
- `inmem` storage means development mode and lost data at the next restart.

<!-- astrona:playground:destroy -->
