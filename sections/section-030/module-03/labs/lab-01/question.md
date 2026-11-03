# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Auth methods

## Scenario

The inventory application must log in to OpenBao and read `secret/inventory/db`. It must not read anything else, such as `secret/billing/db`. The platform team decided to use the AppRole auth method. The policy `inventory-read` already exists and grants the read on the inventory folder.

For this lab only, the unseal key and the root token are in the Secret `openbao-init` (keys `unseal-key` and `root-token`).

Reach the server with `kubectl -n openbao port-forward svc/openbao 8200:8200` in a second terminal and `export BAO_ADDR=http://openbao.localtest.me:8200`.

## Your task

1. Enable the AppRole auth method at `approle/`.
2. Create the role `inventory-app` with the policy `inventory-read`, a token TTL of at most 15 minutes, and secret IDs that can be used more than once (`secret_id_num_uses=0`).
3. Read the role ID of the role and create a secret ID.
4. Store both in the Kubernetes Secret `lab-answer` in the namespace `openbao`, under the keys `role-id` and `secret-id`.

## Constraints

- Do not give the role the `root` policy or any policy other than `inventory-read`.
- Do not change the secrets or the policy.

## Done when

- The role `inventory-app` exists with the policy `inventory-read`, a token TTL of at most 15 minutes and `secret_id_num_uses` of `0`.
- The values in `lab-answer` log in through `auth/approle/login`.
- The resulting token reads `secret/inventory/db` and cannot read `secret/billing/db`.
