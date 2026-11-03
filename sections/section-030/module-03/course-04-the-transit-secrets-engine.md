# The Transit Secrets Engine

The KV engine stores secrets. The **transit** engine stores nothing the application sends. It holds named encryption keys and offers encryption as a service: the application sends data, receives ciphertext, and keeps the ciphertext in its own database. The key never leaves OpenBao, so an application that is breached does not leak the key.

## Create a key

<!-- astrona:playground:renew -->

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
bao secrets enable transit
bao write -f transit/keys/orders
bao read transit/keys/orders
```

The key `orders` is created with the default type `aes256-gcm96`. `bao read` shows the type, the latest version `1`, and the options, but never the key material.

## Encrypt and decrypt

Transit takes plaintext as base64, because the data can be binary:

```sh
PLAINTEXT="$(printf 'card 4111-lab-only' | base64)"
bao write -field=ciphertext transit/encrypt/orders plaintext="$PLAINTEXT"
```

The result starts with `vault:v1:`. The prefix `v1` is the version of the key that encrypted the data. Store the whole string. To decrypt:

```sh
bao write -field=plaintext transit/decrypt/orders ciphertext="vault:v1:<the rest of the value>" | base64 -d
```

OpenBao returns base64 again, so the pipe decodes it. A policy can allow an application `update` on `transit/encrypt/orders` only, which gives it the ability to encrypt and not to decrypt.

## Rotate the key

A key should be replaced regularly, and at once if it may be exposed:

```sh
bao write -f transit/keys/orders/rotate
```

The key now has version 2. New encryptions use version 2 and carry the prefix `vault:v2:`. Old ciphertext still decrypts, because OpenBao keeps the older versions, so rotation needs no change in the application. `min_decryption_version` on the key (set with `bao write transit/keys/orders/config min_decryption_version=2`) refuses decryption with older versions after you have moved all data.

## Rewrap

**Rewrap** converts ciphertext to the latest key version without showing the plaintext to the caller:

```sh
bao write -field=ciphertext transit/rewrap/orders ciphertext="vault:v1:<the rest of the value>"
```

The result starts with `vault:v2:`. After rewrapping all stored values, raise `min_decryption_version`, and a copy of the old ciphertext, such as one in a backup, is no longer readable with the old key.

## What transit does and does not do

- It encrypts and decrypts, signs and verifies, creates hashes and random bytes. It does not store the data.
- It protects against a stolen database, because the ciphertext is useless without OpenBao.
- It does not protect data from an application that is allowed to call decrypt.
- A key with `deletion_allowed=false` (the default) cannot be deleted. Deleting a key makes all its ciphertext unreadable for ever.

## Common pitfalls

> [!WARNING]
> - **Sending plaintext without base64.** The request fails with an error about the encoding.
> - **Deleting a key to rotate it.** All data encrypted with it is lost. Use `rotate`.
> - **Allowing an application both `encrypt` and `decrypt` when it needs one.** Give only the capability it needs.
