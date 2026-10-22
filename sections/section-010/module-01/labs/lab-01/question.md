# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** Seal and unseal

## Scenario

The OpenBao server of the inventory team was restarted during a node upgrade. It came back **sealed**, and the inventory application can no longer read its database password. The server was initialized with five key shares and a threshold of three.

For this lab only, the five key shares are in the Kubernetes Secret `openbao-shares` (keys `share-1` to `share-5`) and the root token is in the Secret `openbao-root` (key `root-token`), both in the namespace `openbao`.

Reach the server from your machine with `kubectl -n openbao port-forward svc/openbao 8200:8200` in a second terminal and `export BAO_ADDR=http://openbao.localtest.me:8200`.

## Your task

1. Unseal the server with the key shares. Use any three of the five.
2. Sign in with the root token and read the secret `secret/inventory/db`.
3. Prove that you read it: write the value of its field `password` to a new secret `secret/inventory/check`, in a field named `password_seen`.

## Constraints

- **Do not initialize the server again.** It already holds its keys and its data.
- Leave the server unsealed, with no unseal operation in progress.
- Do not change the number of key shares or the threshold.

## Done when

- `bao status` shows `Sealed` as `false`, with 5 shares and a threshold of 3.
- The cluster ID and the encryption key are the ones the server had before the restart.
- `secret/inventory/check` holds `password_seen` equal to the `password` in `secret/inventory/db`.
