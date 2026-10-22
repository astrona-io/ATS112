# Summary

`bao operator init` turns an empty server into an initialized one, once. It creates the keys, splits the unseal key into `-key-shares` shares (default five) with a `-key-threshold` (default three), and creates the root token. Its output, best written with `-format=json` or encrypted with `-pgp-keys`, holds every share and the root token, and OpenBao never shows them again. Initialization does not unseal the server.

Unsealing takes a threshold of shares. `bao login` checks a token and stores it in `~/.bao-token`; `BAO_TOKEN` does the same for one terminal and takes priority. A new server needs a secrets engine before it can store data: `bao secrets enable -path=secret kv-v2` enables the KV version 2 engine, and `bao kv put`, `bao kv get` and `-field` write and read secrets, stored under `secret/data/...` in the API. `bao operator seal` throws the keys out of memory; a threshold of shares brings them back.

A running server needs routine care. `bao operator rotate-keys`, which replaced the deprecated `rekey`, creates new unseal shares and can change their number and threshold; it starts with `-init`, takes a `nonce`, and needs a threshold of the current shares. `bao operator rotate` adds a new encryption key to the keyring and raises the key term. The root token is used for setup only: an administrator token with a policy replaces it, and `bao token revoke -self` retires it. `bao operator generate-root` can create a new one later, with a threshold of shares.

The key facts to remember:

- Initialize once; protect the output; hand each share to a different person.
- A new server has no KV engine at `secret/` until you enable one.
- `rotate-keys` changes the unseal shares; `rotate` changes the encryption key.
- No root token in daily use.

<!-- astrona:playground:destroy -->
