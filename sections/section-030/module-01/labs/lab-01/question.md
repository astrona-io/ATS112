# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** The bao CLI

## Scenario

The inventory team has a new OpenBao server. It is installed and running, but nobody has initialized it yet. Before the inventory application goes live, its configuration must be stored in OpenBao.

Reach the server with `kubectl -n openbao port-forward svc/openbao 8200:8200` in a second terminal and `export BAO_ADDR=http://openbao.localtest.me:8200`.

## Your task

1. Initialize the server with **5 key shares and a threshold of 3**. Keep the output on your machine.
2. Unseal it.
3. Enable a **KV version 2** secrets engine at the path `secret/`.
4. Store the secret `secret/app/config` with two fields: `username=app` and `api_url=http://inventory.internal:8080`.
5. So the lab can be graded, store the root token in a Kubernetes Secret named `lab-answer` in the namespace `openbao`, under the key `token`. A real installation never does this.

## Constraints

- Use the `bao` command-line tool for the OpenBao steps.
- Do not store the key shares in the cluster.

## Done when

- The server is initialized with 5 shares and a threshold of 3, and unsealed.
- A KV version 2 secrets engine is enabled at `secret/`.
- `secret/app/config` holds `username=app` and `api_url=http://inventory.internal:8080`.
