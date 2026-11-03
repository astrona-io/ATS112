# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Raft snapshots

## Scenario

The inventory team keeps its database credentials in `secret/inventory/db` on an OpenBao server. A script changed the secret to a wrong password and also wrote a new secret, `secret/inventory/extra`. Nobody can say which other writes the script made. Before the script ran, a Raft snapshot was saved. It is stored in the Kubernetes Secret `pre-change-snapshot` in the namespace `openbao`, under the key `pre-change.snap`.

For this lab only, the unseal key and the root token are in the Secret `openbao-init` (keys `unseal-key` and `root-token`).

Reach the server with `kubectl -n openbao port-forward svc/openbao 8200:8200` in a second terminal and `export BAO_ADDR=http://openbao.localtest.me:8200`.

## Your task

1. Look at the current state of `secret/inventory/db` and `secret/inventory/extra`.
2. Get the snapshot file out of the Kubernetes Secret.
3. Restore the server from the snapshot, so the data is exactly as it was when the snapshot was taken.
4. Bring the server back into service if the restore leaves it sealed or not Ready.

## Constraints

- **Do not initialize the server again.** Its data and keys still exist.
- Restore the snapshot. Writing the old values back by hand does not return the server to the saved state and fails the checks.

## Done when

- `secret/inventory/db` holds the original password and is at version 1.
- `secret/inventory/extra` does not exist, not even as a deleted entry.
- The server is the original cluster.
- The pod `openbao-0` is Ready and the server is unsealed.
