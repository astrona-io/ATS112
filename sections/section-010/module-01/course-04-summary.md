# Summary

OpenBao is an open-source server that stores secrets encrypted and controls who may read them. It is a fork of HashiCorp Vault 1.14, run under LF Projects and the Open Source Security Foundation, which is why its command is `bao` and its variables start with `BAO_`. Every request arrives at the HTTP API, carries a token that the token store checks, passes the policy check, and reaches the secrets engine or auth method that owns its path.

Nothing reaches storage in clear text. The barrier encrypts every value with the encryption keys in the keyring; the root key encrypts the keyring; the unseal key encrypts the root key. OpenBao never stores the unseal key. With the default Shamir seal, initialization splits it into key shares, and any group of shares that reaches the threshold rebuilds it, while a smaller group reveals nothing.

A server is not initialized, initialized and sealed, or initialized and unsealed. A sealed server has all its data but no keys in memory, and it refuses almost every request. Every restart seals it again. `bao status`, `/v1/sys/seal-status` and `/v1/sys/health` report the state; the health endpoint answers `200` when active, `429` when standby, `501` when not initialized and `503` when sealed. Unsealing takes one `bao operator unseal` call per share until the threshold is reached, and `-reset` starts the count again.

The key facts to remember:

- Sealed means "has data, has no key", not "broken".
- Any threshold of shares unseals the server, in any order, from any machine.
- `bao status` exits with `0` when unsealed, `2` when sealed and `1` on an error.
- Auto-unseal replaces people entering shares with an outside key service, and gives recovery keys instead of unseal keys.

<!-- astrona:playground:destroy -->
