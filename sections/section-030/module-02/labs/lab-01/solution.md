# Solution: Create A Read-Only Policy And Token

Work the task yourself first. Running `astrona submit -c sections/section-030/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: the policy exists, the token has the policy and a short TTL and is not root, the token reads and lists `inventory/` and cannot write, and the token cannot read `billing/`.

## Step 1: Sign in and look at the secrets

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
bao kv list secret/
bao kv get secret/inventory/db
```

The engine is KV version 2, so the API paths are `secret/data/...` for values and `secret/metadata/...` for names and metadata.

## Step 2: Write the policy

Save this as `inventory-read.hcl`:

```hcl
path "secret/data/inventory/*" {
  capabilities = ["read"]
}

path "secret/metadata/inventory/*" {
  capabilities = ["read", "list"]
}
```

Load it:

```sh
bao policy write inventory-read inventory-read.hcl
bao policy read inventory-read
```

## Step 3: Create the token and store it

```sh
TOKEN="$(bao token create -policy=inventory-read -ttl=1h -format=json | jq -r '.auth.client_token')"
kubectl -n openbao create secret generic lab-answer --from-literal=token="$TOKEN"
```

If you have no `jq`, read the token from the output of `bao token create -field=token -policy=inventory-read -ttl=1h`.

## Step 4: Test as the application

Test with the new token, not the root token:

```sh
bao token capabilities "$TOKEN" secret/data/inventory/db
bao token capabilities "$TOKEN" secret/data/billing/db
BAO_TOKEN="$TOKEN" bao kv get secret/inventory/db
BAO_TOKEN="$TOKEN" bao kv get secret/billing/db
```

The first line prints `read`, the second prints `deny`. The third command shows the secret, and the fourth fails with `permission denied`. Send the lab for grading:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Write the rule for `secret/inventory/*` | In KV version 2 the data is at `secret/data/inventory/*`; the token gets `403` on the read |
| Give the token the `default` policy only and the root token to the application | The grader fails the token for the `root` policy |
| Create the token without `-ttl` | The token takes the default TTL of the server, which can be longer than one hour |
| Add `create` and `update` to the policy | The write check expects `403` |

## Common mistakes

- Storing the output of the whole `bao token create` command instead of the token value.
- Testing with the root token, which can read everything and proves nothing.
