# Initializing A Server

A server that is not initialized has empty storage and no keys. It can do exactly one useful thing: be initialized. This part runs that command, explains the two numbers you must choose, and goes through what the command prints, because that output is the most sensitive data the server will ever produce.

## Before initialization

Check the state of your playground's server first:

<!-- astrona:playground:renew -->

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
bao status
```

`Initialized` is `false` and `Sealed` is `true`. A server that is not initialized always reports sealed, because it has no keys at all. `/v1/sys/health` answers `501` in this state. `bao operator init -status` asks only the question "is it initialized?" and exits with `0` for yes and `2` for no.

## Choosing shares and a threshold

`bao operator init` creates the keys and splits the unseal key with Shamir's secret sharing. Two flags decide how:

- `-key-shares` is the number of shares to create. The default is `5`.
- `-key-threshold` is the number of shares needed to unseal. The default is `3`.

The threshold is a balance. With a threshold of 1, any single person who holds a share can unseal the server. With a threshold equal to the number of shares, losing one share makes the server impossible to unseal. A threshold of three out of five survives two lost shares and needs three people to agree.

## Running the command

Initialize your playground's server with five shares and a threshold of three, and keep the output in a file:

```sh
bao operator init -key-shares=5 -key-threshold=3 -format=json > init.json
```

`-format=json` writes the output as JSON, so a tool can read single values from it. Look at the field names without printing the secrets:

```sh
jq 'keys' init.json
```

The fields include `unseal_keys_b64` and `unseal_keys_hex`, two lists that hold the same five shares in Base64 and hexadecimal form, `unseal_shares` and `unseal_threshold`, and `root_token`. Without `-format=json`, the command prints the same data as a text table and reminds you to store the shares safely.

## Handling the output

Everything in `init.json` is critical. The shares can unseal the server, and the root token can do everything on it. OpenBao never shows them again: if all copies are lost before the threshold of shares is given to their holders, the server can never be unsealed after its next restart.

On a real server, initialization is a small ceremony. Each share goes to a different person, ideally encrypted for them. The flag `-pgp-keys` takes a list of public PGP (Pretty Good Privacy) keys, one per share, so each share is printed already encrypted for its holder; `-root-token-pgp-key` does the same for the root token. Afterwards the file is deleted.

Check the state again:

```sh
bao status
```

`Initialized` is now `true`, `Sealed` is still `true`, `Total Shares` is `5` and `Threshold` is `3`. Initialization does not unseal the server; that is the next step.

You now know what initialization creates, how to choose the shares and the threshold, and why its output must be handled with care. The open question is how to bring the new server into use.

## Common pitfalls

> [!WARNING]
> - **Choosing a threshold of 1 for convenience.** Any single share then unseals the server, which defeats the split.
> - **Losing the output.** OpenBao never shows the shares or the root token again.
> - **Running init in a terminal that is logged or shared.** The output contains every key. Use `-format=json` into a file you delete, or PGP keys.
