# Solution: Rotate Unseal Keys And Retire The Root Token

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: 5 shares and a threshold of 3 on the original cluster, a higher encryption key term, a revoked root token, and an admin token in `lab-answer` that reads `secret/inventory/db`.

## Step 1: Sign in and look at the starting point

Start the port-forward in a second terminal, then:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
bao status
bao operator key-status
```

`bao status` shows `Total Shares` `1` and `Threshold` `1`. Note the `Key Term` from `key-status`.

## Step 2: Rotate the unseal keys

Start the rotation with the new layout, then complete it with the current single share:

```sh
bao operator rotate-keys -init -key-shares=5 -key-threshold=3 -format=json > rotate-start.json
NONCE="$(jq -r '.nonce' rotate-start.json)"
OLD_KEY="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.unseal-key}' | base64 -d)"
bao operator rotate-keys -nonce="$NONCE" -format=json "$OLD_KEY" > rotate-done.json
```

Because the old threshold is 1, one share completes the rotation. `rotate-done.json` holds the five new shares under `keys_base64`, and `bao status` now shows 5 shares and a threshold of 3. Store the new shares as the task asks:

```sh
kubectl -n openbao create secret generic openbao-shares \
  --from-literal=share-1="$(jq -r '.keys_base64[0]' rotate-done.json)" \
  --from-literal=share-2="$(jq -r '.keys_base64[1]' rotate-done.json)" \
  --from-literal=share-3="$(jq -r '.keys_base64[2]' rotate-done.json)" \
  --from-literal=share-4="$(jq -r '.keys_base64[3]' rotate-done.json)" \
  --from-literal=share-5="$(jq -r '.keys_base64[4]' rotate-done.json)"
```

## Step 3: Rotate the encryption key

```sh
bao operator rotate
bao operator key-status
```

The `Key Term` is one higher than in step 1.

## Step 4: Create the admin policy and token

Save this as `policy-admin.hcl`:

```hcl
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
```

Write the policy, create a token with it, and test the token before you rely on it. Create it with `-orphan`: a token made by the root token is otherwise its child, and revoking the root token in the next step would revoke it too.

```sh
bao policy write admin policy-admin.hcl
ADMIN_TOKEN="$(bao token create -orphan -policy=admin -ttl=24h -field=token)"
BAO_TOKEN="$ADMIN_TOKEN" bao kv get secret/inventory/db
kubectl -n openbao create secret generic lab-answer --from-literal=token="$ADMIN_TOKEN"
```

The `kv get` with the admin token shows the secret.

## Step 5: Revoke the root token

`BAO_TOKEN` still holds the root token, so it revokes itself:

```sh
bao token revoke -self
bao token lookup
```

`bao token lookup` now fails: the root token no longer exists. Send the capstone for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Initialize again with 5 shares | Impossible on an initialized server; on new storage you would lose `secret/inventory/db` |
| Store the root token in `lab-answer` | The grader rejects a root token, and the root token must be revoked |
| Revoke the root token first | You can no longer create the policy or the admin token without `bao operator generate-root` |

## Common mistakes

- Confusing `rotate` (encryption key) with `rotate-keys` (unseal shares).
- Starting a second rotation while one is pending; cancel it with `bao operator rotate-keys -cancel`.
- Forgetting that the old single unseal key stops working after the rotation.
