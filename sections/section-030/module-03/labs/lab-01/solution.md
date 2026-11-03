# Solution: Give An Application An AppRole Login

Work the task yourself first. Running `astrona submit -c sections/section-030/module-03/labs/lab-01` after a step tells you which checks pass.

The grader checks two things: the role is configured as asked, and the values in `lab-answer` log in with the expected access.

## Step 1: Sign in and enable the method

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
bao auth enable approle
```

## Step 2: Create the role

```sh
bao write auth/approle/role/inventory-app \
  token_policies=inventory-read \
  token_ttl=15m \
  token_max_ttl=1h \
  secret_id_ttl=24h \
  secret_id_num_uses=0
bao read auth/approle/role/inventory-app
```

The last command shows the settings, including `token_policies` and `token_ttl` (900 seconds).

## Step 3: Get the role ID and a secret ID, and store them

```sh
ROLE_ID="$(bao read -field=role_id auth/approle/role/inventory-app/role-id)"
SECRET_ID="$(bao write -f -field=secret_id auth/approle/role/inventory-app/secret-id)"
kubectl -n openbao create secret generic lab-answer \
  --from-literal=role-id="$ROLE_ID" --from-literal=secret-id="$SECRET_ID"
```

## Step 4: Test as the application

```sh
bao write auth/approle/login role_id="$ROLE_ID" secret_id="$SECRET_ID"
```

The response holds a token with the policies `default` and `inventory-read`. Use it to read the two secrets:

```sh
APP_TOKEN="$(bao write -field=token auth/approle/login role_id="$ROLE_ID" secret_id="$SECRET_ID")"
BAO_TOKEN="$APP_TOKEN" bao kv get secret/inventory/db
BAO_TOKEN="$APP_TOKEN" bao kv get secret/billing/db
```

The first read works. The second fails with `permission denied`. Send the lab for grading:

```sh
astrona submit -c sections/section-030/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Set `secret_id_num_uses=1` | The grader's login uses the secret ID up, and a second `astrona submit` fails |
| Store a root token in `lab-answer` | The grader needs `role-id` and `secret-id`, and rejects the root policy |
| Forget `-f` on the secret ID command | The command reports an error about missing parameters |

## Common mistakes

- Printing the secret ID once and not saving it. It cannot be read again; create a new one.
- Swapping the role ID and the secret ID in the Secret.
