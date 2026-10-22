# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Storage and configuration

## Scenario

The platform team tried OpenBao with the quick-start command and kept it running. Today OpenBao runs in **development mode**: in memory, unsealed, with nothing that survives a restart. Before any application stores a secret in it, the team wants a real server.

OpenBao was installed with Helm: release `openbao`, chart `openbao/openbao` version `0.30.4`, namespace `openbao`.

Reach the server with `kubectl -n openbao port-forward svc/openbao 8200:8200` in a second terminal and `export BAO_ADDR=http://openbao.localtest.me:8200`.

## Your task

1. Replace development mode with a standalone server whose configuration has:
   - a `listener "tcp"` on `[::]:8200` with the cluster address `[::]:8201` (TLS stays off, lab-only);
   - Integrated Storage: `storage "raft"` with `path = "/openbao/data"` and `node_id = "openbao-0"`;
   - `api_addr = "http://openbao.localtest.me:8200"`;
   - the web UI on (`ui = true`) and `log_level = "warn"`.
2. Initialize the new server with **3 key shares and a threshold of 2**, and unseal it.
3. Enable a KV version 2 secrets engine at `secret/` and store `secret/platform/owner` with `team=platform`.
4. Store a token that can read that secret in a Kubernetes Secret named `lab-answer` in the namespace `openbao`, under the key `token`. This is only so the lab can be graded.

## Constraints

- Make the change through the Helm release.
- Keep the key shares out of the cluster; only the token goes into `lab-answer`.

## Done when

- The Helm release no longer uses development mode, and the server reports Raft storage.
- The server is initialized with 3 shares and a threshold of 2, and unsealed.
- The configuration has the UI on, `log_level = "warn"`, the `api_addr` and the listener on `[::]:8200`.
- The token in `lab-answer` works and reads `team=platform` from `secret/platform/owner`.
