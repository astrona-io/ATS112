# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Security model

## Scenario

The inventory team's OpenBao server is sealed after a restart. Five key shares and a threshold of three protect it. One of the five people who hold a share reports that their copy was damaged when they moved it to a new laptop, but nobody remembers whose copy it was.

For this lab only, all five shares are in the Kubernetes Secret `openbao-shares` (keys `share-1` to `share-5`) and the root token is in the Secret `openbao-root` (key `root-token`), both in the namespace `openbao`. **One of the five shares is wrong.**

Reach the server with `kubectl -n openbao port-forward svc/openbao 8200:8200` in a second terminal and `export BAO_ADDR=http://openbao.localtest.me:8200`.

## Your task

1. Unseal the server.
2. Find out which share is wrong. Record it as a secret: write `secret/ops/bad-share` with a field `name` set to the share's key name, for example `name=share-4`.
3. Confirm from inside the cluster that the server reports itself healthy on `/v1/sys/health`.

## Constraints

- **Do not initialize the server again**, and do not change the shares or the threshold.
- Leave the server unsealed at the end, with no unseal operation in progress.
- Record exactly one share name.

## Done when

- The server is unsealed with 5 shares and a threshold of 3, on its original cluster and encryption key.
- `secret/ops/bad-share` names the wrong share.
- `/v1/sys/health` answers `200` from the `tester` pod in the namespace `clients`.
