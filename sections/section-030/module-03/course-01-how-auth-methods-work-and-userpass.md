# How Auth Methods Work, And Userpass

An auth method is a plugin mounted below `auth/`. It answers one question: is this caller who it says it is? If yes, OpenBao creates a token for the caller, with the policies that the method assigns. After login, the method plays no further part. Every later request carries the token, and the policies decide.

## The login flow

1. The client sends credentials to a login path, such as `auth/userpass/login/alice`.
2. The method checks the credentials against its own data or an outside system.
3. The method returns a token with a TTL and a list of policies.
4. The client sends the token in the header `X-Vault-Token` on every later request.

Login paths do not need a token, because the caller has none yet. Everything else in the method, such as creating users, needs a token with a policy.

## List and enable methods

```sh
bao auth list
```

A new server has one method, `token/`, which handles the tokens you made with `bao token create`. The command `bao auth enable` mounts another one:

<!-- astrona:playground:renew -->

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
bao auth enable userpass
bao auth list
```

The method is mounted at `userpass/` by default. The option `-path=people` mounts it at another path, which allows two instances of one method. The `auth list` output shows the type and the accessor of each mount. An **accessor** is an identifier that stays the same if you rename the mount, and policies and audit logs can refer to it.

## Userpass

The `userpass` method stores user names and password hashes inside OpenBao. It suits small installations and labs. Larger installations use an outside identity provider, with a method such as OIDC or LDAP, and the steps are the same: enable, configure, map identities to policies, log in.

Create a policy and a user that has it. The policy is the one from the previous module:

```sh
bao secrets enable -path=secret kv-v2
bao policy write inventory-read - <<'POLICY'
path "secret/data/inventory/*" {
  capabilities = ["read"]
}
POLICY
bao write auth/userpass/users/alice password=lab-only-password policies=inventory-read token_ttl=30m
```

`bao policy write` with `-` as the file name reads the policy from standard input. The user holds the policy name and the TTL of the tokens that its logins create.

## Logging in

```sh
bao login -method=userpass username=alice password=lab-only-password
```

The command prints the token and its policies, and saves the token in `~/.bao-token`, as `bao login` does with any token. A password on the command line stays in the shell history; omit `password=` and the command asks for it. For a script, call the API path and keep the token in a variable:

```sh
bao write -format=json auth/userpass/login/alice password=lab-only-password | jq -r '.auth.client_token'
```

The result holds `policies` (`default` and `inventory-read`) and `lease_duration` (1800 seconds for 30 minutes). Use `bao token lookup` with the new token to see its `ttl`, and `bao token capabilities` to test a path.

## Removing access

Delete the user and the access ends for new logins:

```sh
bao delete auth/userpass/users/alice
```

Tokens that the user already received stay valid until they expire. To end them at once, revoke by the mount: `bao token revoke -mode=path auth/userpass`, or revoke one token with `bao token revoke`. Short token TTLs make this less urgent.

## Common pitfalls

> [!WARNING]
> - **Leaving `bao login` tokens in `~/.bao-token`.** The file holds a token that works until it expires. Delete the file when you finish, and use short TTLs.
> - **Putting a password on the command line.** It stays in the shell history.
> - **Deleting a user and assuming its tokens are gone.** They live until they expire or are revoked.
