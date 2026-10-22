# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Server configuration

## Scenario

A colleague "tidied up" the configuration of the inventory team's OpenBao server and rolled it out. Since then the pod `openbao-0` is not Ready, and applications cannot reach the server. The colleague says no data was deleted, but nobody can read a secret.

The server was installed with Helm: release `openbao`, chart `openbao/openbao` version `0.30.4`, namespace `openbao`. Before the change it listened on port `8200` and kept its Raft data in `/openbao/data`. For this lab only, the unseal key and the root token are in the Secret `openbao-init` (keys `unseal-key` and `root-token`).

Reach the server with `kubectl -n openbao port-forward svc/openbao 8200:8200` in a second terminal and `export BAO_ADDR=http://openbao.localtest.me:8200`.

## Your task

1. Find what in the configuration stops the server from serving its data.
2. Correct the configuration **through the Helm release**, and make the server run with it.
3. Bring the server back into service: unsealed, Ready, and serving the secret `secret/inventory/db` it held before the change.

## Constraints

- **Do not initialize the server again.** Its data and keys still exist.
- Change the configuration with `helm upgrade`, not by editing the ConfigMap.
- Keep the Raft storage, the listener on port `8200` and the rest of the configuration as it was before the change.

## Done when

- The server configuration listens on `[::]:8200` and keeps Raft data in `/openbao/data`.
- `bao operator validate-config` accepts the configuration the pod runs with.
- The pod `openbao-0` is Ready and the server is unsealed.
- The server is the original cluster, and `secret/inventory/db` is readable with the original root token.
