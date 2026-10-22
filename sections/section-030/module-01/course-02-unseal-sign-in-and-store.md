# Unseal, Sign In, Store A Secret And Seal Again

An initialized server is still sealed and still empty. Before an application can read a secret from it, an operator must unseal it, sign in, enable a secrets engine and write the first secret. This part does all four, then seals the server on purpose so you see the whole cycle.

## Unsealing the new server

Your playground server is initialized; the output is in `init.json`. Enter three of the five shares:

<!-- astrona:playground:renew -->

```sh
bao operator unseal "$(jq -r '.unseal_keys_b64[0]' init.json)"
bao operator unseal "$(jq -r '.unseal_keys_b64[1]' init.json)"
bao operator unseal "$(jq -r '.unseal_keys_b64[2]' init.json)"
```

After the third share, `Sealed` is `false`. If you did not initialize the server yourself, run `bao operator init -key-shares=5 -key-threshold=3 -format=json > init.json` first.

## Signing in

Every request beyond the seal status needs a token. `bao login` takes a token, checks it with the server, and stores it in a token helper file on your machine (`~/.bao-token`) so later commands send it automatically:

```sh
bao login "$(jq -r '.root_token' init.json)"
```

The output shows the token's details: its policies are only `root`, and it has no expiry time, because a root token never expires. Setting the environment variable `BAO_TOKEN` has the same effect for the current terminal, and it takes priority over the token helper file.

## Enabling a secrets engine and writing a secret

A new server has no secrets engine for your data. A **secrets engine** is a component mounted at a path that stores or creates secrets. The KV (key-value) engine stores fixed values; version 2 keeps old versions of each secret. Enable it at the path `secret/`:

```sh
bao secrets enable -path=secret kv-v2
bao secrets list
```

The list now shows `secret/` with the type `kv`, next to the built-in mounts `cubbyhole/`, `identity/` and `sys/`. Write a secret with two fields and read it back:

```sh
bao kv put secret/app/config username=app api_url=http://inventory.internal:8080
bao kv get secret/app/config
```

`bao kv put` reports the new version, `1`. `bao kv get` shows the metadata, such as the creation time and version, then the two fields. `bao kv get -field=api_url secret/app/config` prints one field only, which is what scripts use. Behind the `bao kv` command, KV version 2 stores the data under the API path `secret/data/app/config`.

## Sealing on purpose

Sealing throws the keys out of memory. An operator does it when an attack is suspected, because nobody can read anything afterwards until a threshold of share holders unseals the server again. It needs a token with root or `sudo` rights:

```sh
bao operator seal
bao kv get secret/app/config
```

The `kv get` now fails because the server is sealed. Unseal it again with any three shares from `init.json`, and the secret is readable again: the data never changed, only the keys in memory.

You can now take a fresh server all the way to a stored secret and back to sealed. The next step is to do it on your own, on a server nobody has touched yet.

## Common pitfalls

> [!WARNING]
> - **Forgetting the KV version.** `bao secrets enable kv` creates version 1, which keeps no history; use `kv-v2`.
> - **Reading KV version 2 with the wrong API path.** Over HTTP, the data lives under `secret/data/...`; the `bao kv` command adds `data/` for you.
> - **Leaving `~/.bao-token` with a root token on a shared machine.** Run `bao token revoke -self` or delete the file when you are done.

## Your mission: Initialize OpenBao And Store A First Secret

You can now initialize a server, unseal it, sign in and store a secret. The graded lab gives you a server that nobody has initialized, and asks you to set it up with five shares and a threshold of three and store the inventory application's configuration in it.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-112-playground-030-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS112.git -c sections/section-030/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-112-lab-030-01
astrona start ats-112-playground-030-01
```
