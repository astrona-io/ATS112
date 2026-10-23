# Rotating Keys And Retiring The Root Token

A server that runs for years outlives the people who set it up. Share holders change jobs, and a root token that was pasted into a terminal once may sit in a log file. This part covers the routine work that keeps a running server safe: new unseal keys, a new encryption key, and no root token in daily use.

## New unseal keys with rotate-keys

`bao operator rotate-keys` creates a new set of unseal key shares, and it can change the number of shares and the threshold at the same time. The server stays unsealed and keeps serving requests. It still needs a threshold of the **current** shares to authorize the change. In older guides you will meet the same command as `bao operator rekey`; OpenBao deprecated that name in version 2.4.0 in favour of `rotate-keys`.

Rotation is a two-step process. First you start it with the new layout. Your playground's server uses five shares with a threshold of three; replace them with seven shares and a threshold of four:

<!-- astrona:playground:renew -->

```sh
export BAO_TOKEN="$(jq -r '.root_token' init.json)"
bao operator rotate-keys -init -key-shares=7 -key-threshold=4 -format=json > rotate-start.json
jq -r '.nonce' rotate-start.json
```

The output of the first command includes a `nonce`, a one-time value that ties the next steps to this rotation. Then each holder of a current share enters it with that nonce, until the old threshold, three, is reached:

```sh
NONCE="$(jq -r '.nonce' rotate-start.json)"
bao operator rotate-keys -nonce="$NONCE" -format=json "$(jq -r '.unseal_keys_b64[0]' init.json)"
bao operator rotate-keys -nonce="$NONCE" -format=json "$(jq -r '.unseal_keys_b64[1]' init.json)"
bao operator rotate-keys -nonce="$NONCE" -format=json "$(jq -r '.unseal_keys_b64[2]' init.json)" > rotate-done.json
```

The last call completes the rotation, and `rotate-done.json` holds the seven new shares under `keys_base64`. The old shares stop working at once. `bao status` now shows `Total Shares` `7` and `Threshold` `4`. The `-verify` flag adds a step in which the new holders prove they received their shares before the old ones stop working, which protects against a typing mistake during the ceremony.

## A new encryption key with rotate

`bao operator rotate` adds a new encryption key to the keyring. New data is written with the new key, and the older keys stay in the keyring to read older data. It needs no key shares and causes no downtime:

```sh
bao operator key-status
bao operator rotate
```

`key-status` shows the current `Key Term`, the number of the active encryption key; after `rotate` it is one higher. Rotating the encryption key limits how much data any one key has encrypted, and it is a normal step after an incident.

## Retiring the root token

The root token can do everything and never expires, so it should not exist in daily use. The usual pattern is to create an administrator policy and a normal token with it, then revoke the root token. Save this as `policy-admin.hcl`:

```hcl
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
```

Write the policy and create a token with it that is valid for 24 hours. A token that another token creates is its child, and revoking a token also revokes all its children. `-orphan` creates the token without a parent, so it survives when the root token is revoked:

```sh
bao policy write admin policy-admin.hcl
bao token create -orphan -policy=admin -ttl=24h
```

The output shows the new `token` and its `token_policies`, `["admin" "default"]`. Unlike the root token, it expires and it can be revoked alone. A real setup gives each administrator their own sign-in method and a tighter policy than full access to every path.

Then revoke the root token. With the root token still in `BAO_TOKEN`, it revokes itself:

```sh
bao token revoke -self
```

From now on, the old root token fails on every request. When a root token is needed again, for example after all administrator access is lost, `bao operator generate-root` creates a new one. It needs a threshold of unseal key shares, so no single person can do it alone.

You can now replace the unseal keys, rotate the encryption key and run a server without a root token in use. Together with initializing, unsealing and sealing, that is the full set of operator commands this module set out to teach.

## Common pitfalls

> [!WARNING]
> - **Mixing old and new shares.** After `rotate-keys` completes, the old shares stop working. Hand out the new ones at once.
> - **Revoking the root token before an administrator token works.** Test the new token first, with `bao token lookup` and a real read.
> - **Creating the administrator token without `-orphan`.** It is a child of the root token, so `bao token revoke -self` revokes it too.
> - **Thinking `rotate` changes the unseal keys.** `rotate` changes the encryption key in the keyring; `rotate-keys` changes the unseal key shares.
