# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Policies and tokens

## Scenario

The inventory application must read the credentials in `secret/inventory/db` and list the folder `inventory/`. It must not read anything else. The server also holds `secret/billing/db`, which belongs to another team. The application currently has no credential, and nobody may give it the root token.

The secrets engine is KV version 2, mounted at `secret/`. For this lab only, the unseal key and the root token are in the Secret `openbao-init` (keys `unseal-key` and `root-token`).

Reach the server with `kubectl -n openbao port-forward svc/openbao 8200:8200` in a second terminal and `export BAO_ADDR=http://openbao.localtest.me:8200`.

## Your task

1. Write a policy named `inventory-read` that allows `read` on the data of every secret below `inventory/`, and `read` and `list` on its metadata.
2. Create a token that has the policy `inventory-read` and a TTL of at most one hour.
3. Store the token in the Kubernetes Secret `lab-answer` in the namespace `openbao`, under the key `token`.

## Constraints

- The token must not have the `root` policy. Use the root token only to set things up.
- The policy must not allow any capability other than the ones named above.
- Do not change the secrets.

## Done when

- The policy `inventory-read` exists.
- The token in `lab-answer` is valid, has the policy `inventory-read`, does not have `root`, and expires within one hour.
- The token reads and lists `inventory/` and cannot write there.
- The token cannot read `secret/billing/db`.
