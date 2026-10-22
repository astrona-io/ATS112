# Solution: Initialize OpenBao And Store A First Secret

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the server has 5 shares and a threshold of 3 and is unsealed, `secret/` is a KV version 2 engine, and `secret/app/config` holds the two values. It reads them with the token in `lab-answer`.

## Step 1: Check the state

Start the port-forward in a second terminal, then:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
bao status
```

`Initialized` is `false`. The server is waiting for its first command.

## Step 2: Initialize

```sh
bao operator init -key-shares=5 -key-threshold=3 -format=json > init.json
```

`init.json` holds the five shares in `unseal_keys_b64` and the root token in `root_token`. `bao status` now shows `Initialized` `true`, `Sealed` `true`, 5 shares and a threshold of 3.

## Step 3: Unseal and sign in

Enter three shares, then sign in with the root token:

```sh
bao operator unseal "$(jq -r '.unseal_keys_b64[0]' init.json)"
bao operator unseal "$(jq -r '.unseal_keys_b64[1]' init.json)"
bao operator unseal "$(jq -r '.unseal_keys_b64[2]' init.json)"
bao login "$(jq -r '.root_token' init.json)"
```

After the third share, `Sealed` is `false`.

## Step 4: Enable KV version 2 and store the secret

```sh
bao secrets enable -path=secret kv-v2
bao kv put secret/app/config username=app api_url=http://inventory.internal:8080
bao kv get secret/app/config
```

`bao kv get` shows both fields.

## Step 5: Hand the token to the grader and submit

```sh
kubectl -n openbao create secret generic lab-answer --from-literal=token="$(jq -r '.root_token' init.json)"
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Initialize with the defaults and a threshold of 1 | The grader checks for 5 shares and a threshold of 3 |
| `bao secrets enable kv` | That creates KV version 1; the grader checks for version 2 |
| Write `secret/data/app/config` with `bao kv put` | `bao kv` adds `data/` itself, so the secret ends up at the wrong path |

## Common mistakes

- Losing `init.json` before unsealing: the shares are shown only once.
- Forgetting `bao login`, so `bao secrets enable` fails with a permission error.
- Typing `api_url` with `https`; the grader compares the value exactly.
