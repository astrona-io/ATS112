# Solution: Unseal A Server With A Key Threshold

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the server is unsealed with 5 shares and a threshold of 3 and no unseal in progress, it is still the original cluster with the original encryption key, and `secret/inventory/check` holds the right password.

## Step 1: Reach the server and read its state

Start the port-forward in a second terminal, then set the address and ask for the status:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
bao status
```

`Initialized` is `true`, `Sealed` is `true`, `Total Shares` is `5` and `Threshold` is `3`. The command exits with code `2`, which means sealed. The server needs three shares, not a new initialization.

## Step 2: Enter three shares

Define a small helper that prints one share from the lab's Secret:

```sh
share() {
  kubectl -n openbao get secret openbao-shares -o jsonpath="{.data.share-$1}" | base64 -d
}
```

Enter any three shares, one call each. This walkthrough uses shares 2, 4 and 5:

```sh
bao operator unseal "$(share 2)"
bao operator unseal "$(share 4)"
bao operator unseal "$(share 5)"
```

The first two calls report `Unseal Progress` `1/3` and `2/3`. After the third, `Sealed` is `false` and the progress is back to `0`.

## Step 3: Read the secret and prove it

Sign in with the root token from the lab's Secret, read the password and write it to the new secret:

```sh
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-root -o jsonpath='{.data.root-token}' | base64 -d)"
PASSWORD="$(bao kv get -field=password secret/inventory/db)"
bao kv put secret/inventory/check password_seen="$PASSWORD"
```

The last command reports the metadata of the new secret: its creation time and version `1`.

## Step 4: Check and submit

Run `bao status` once more and confirm `Sealed` is `false`. Then send the lab for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Run `bao operator init` | The server is already initialized, so the command fails. On new storage it would create new keys and an empty server, and the grader sees a new cluster ID |
| Enter only two shares | The server stays sealed with `progress` at 2 of 3 |
| Lower the threshold | Changing shares or threshold needs the server unsealed first, and the task forbids it |

## Common mistakes

- Forgetting `export BAO_ADDR=...` in the terminal where you run `bao`.
- Copying a share with an extra space or line break. Use the helper instead of copying by hand.
- Closing the port-forward terminal. `bao` then fails with a connection error.
