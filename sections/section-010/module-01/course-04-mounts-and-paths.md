# Mounts, Secrets Engines And Auth Methods

A request to OpenBao is a path, and the path decides which code handles it. This part opens the router: it lists the built-in mounts, shows how secrets engines and auth methods are attached at paths, and explains why disabling one deletes its data.

## Everything is a path

Every request carries an HTTP method and a path that starts with `/v1/`. The router compares the path with a table of **mounts**. A mount is a component attached at a path prefix. The router finds the longest matching prefix and gives the request to the component mounted there.

There are two kinds of components. A **secrets engine** stores, generates or encrypts data, for example the KV engine that stores fixed values. An **auth method** checks a credential and returns a token, for example the `userpass` method that checks a user name and password. Secrets engines live under their own paths, and auth methods always live under `auth/`.

If the server is sealed, unseal it with any three of the five shares from the Secret `openbao-shares` first. Then sign in with the root token and list the mounts:

<!-- astrona:playground:renew -->

```sh
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-root -o jsonpath='{.data.root-token}' | base64 -d)"
bao secrets list
bao auth list
```

`bao secrets list` shows the mounts `cubbyhole/`, `identity/`, `sys/` and the `secret/` engine that the playground created. `bao auth list` shows `token/`, the built-in method that creates and checks tokens. These mounts exist on every server and cannot be removed.

## The built-in mounts

Three mounts are always there:

- `sys/` is the system backend. It serves the seal, health, policy, mount and audit endpoints that this course uses. A request to `sys/seal-status` is handled by it.
- `cubbyhole/` is a private storage area for each token. A token can read only its own cubbyhole, and the data is deleted when the token is revoked.
- `identity/` stores entities and groups that tie several logins to one person or service.

Everything else is a mount that an operator enabled. Show the details of each, including its type and its accessor, a unique identifier for the mount:

```sh
bao secrets list -detailed
```

## Enabling, tuning, moving and disabling

You attach an engine to a path with `bao secrets enable`. The `-path` option sets the prefix, and the engine type sets the behavior. The same type can be mounted at several paths, each with its own data:

```sh
bao secrets enable -path=team-a kv-v2
bao secrets enable -path=team-b kv-v2
bao kv put team-a/config owner=a
bao kv put team-b/config owner=b
```

The two engines do not see each other's data, because the router sends a request for `team-a/` and a request for `team-b/` to different components. Mount settings, such as the default and maximum lease time for tokens and secrets that the mount issues, are changed with `bao secrets tune`:

```sh
bao secrets tune -default-lease-ttl=1h -max-lease-ttl=24h team-a
```

`bao secrets move team-a team-c` changes the path of a mount and keeps its data. The move is not instant for large engines, and clients that use the old path fail until they change.

`bao secrets disable team-b/` removes the mount and deletes everything stored in it. It does not ask for confirmation and it cannot be undone, except by a snapshot restore of the whole cluster. Treat `disable` like a delete of a database.

```sh
bao secrets disable team-b/
bao secrets disable team-c/
```

## Auth methods work the same way

`bao auth enable userpass` attaches the method at `auth/userpass/`, and `bao auth list` shows it. A user created in that method logs in with `bao login -method=userpass username=...`, and the method returns a token with the policies set for that user. Tokens and policies decide who may use each path.

You can now say which component answers a path, and which mounts a new server has. Every one of these paths demands a token, and the policies on that token decide what it may do.

## Common pitfalls

> [!WARNING]
> - **Mixing up mount paths.** `secret/` and `secrets/` are two different mounts. A request to a path with no mount returns an error.
> - **Disabling a mount to "reset" it.** All its data is deleted.
> - **Looking for auth methods in `bao secrets list`.** Auth methods appear only in `bao auth list`.
