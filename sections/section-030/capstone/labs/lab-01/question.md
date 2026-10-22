# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Seal and key operations

## Scenario

The inventory team's OpenBao server was set up in a hurry: it was initialized with a **single key share**, and the root token is still used for daily work. A security review asks for four changes before the server holds more secrets.

For this lab only, the current unseal key and the root token are in the Kubernetes Secret `openbao-init` (keys `unseal-key` and `root-token`) in the namespace `openbao`. The server is unsealed.

Reach the server with `kubectl -n openbao port-forward svc/openbao 8200:8200` in a second terminal and `export BAO_ADDR=http://openbao.localtest.me:8200`.

## Your task

1. Replace the single unseal key with **5 key shares and a threshold of 3**, without initializing the server again. For this lab only, store the five new shares in a Secret named `openbao-shares` (keys `share-1` to `share-5`) in the namespace `openbao`.
2. Rotate the encryption key of the keyring.
3. Create a policy named `admin` with this content, and a token with that policy (not a root token). Store the token in a Secret named `lab-answer` in the namespace `openbao`, under the key `token`.

   ```hcl
   path "*" {
     capabilities = ["create", "read", "update", "delete", "list", "sudo"]
   }
   ```

4. Revoke the root token.

## Constraints

- **Do not initialize the server again**; the secret `secret/inventory/db` must survive.
- Leave the server unsealed.
- Revoke the root token last, after the admin token works.

## Done when

- The server uses 5 key shares with a threshold of 3, on its original cluster, and is unsealed.
- The encryption key term is higher than at the start.
- The original root token no longer works.
- The token in `lab-answer` has the `admin` policy, is not a root token, and can read `secret/inventory/db`.
