# Initialize, Unseal And Operate OpenBao

A new OpenBao server has no keys, no data and no token. One command creates all of them, and from that moment the server depends on the people who hold its key shares and on how carefully its root token is handled. This module walks through the life of a server from that first command to the routine work of rotating its keys.

Keep one sentence in mind: **initialization happens once per server, and everything it prints must be handled with care.**

The module has three parts. **Initializing A Server** runs `bao operator init` and explains each choice and each line of its output. **Unseal, Sign In, Store A Secret And Seal Again** brings the new server into use and shows sealing on purpose; a graded lab follows it. **Rotating Keys And Retiring The Root Token** covers the work that keeps a running server safe.

## Learning objectives

After this module you can:

- Initialize a server with a chosen number of key shares and threshold, and read the output.
- Unseal a server and sign in with `bao login`.
- Enable a KV version 2 secrets engine and write, read and list secrets with `bao kv`.
- Seal a server on purpose and explain what that does.
- Replace the unseal keys with `bao operator rotate-keys` and rotate the encryption key with `bao operator rotate`.
- Create an administrator token with a policy and revoke the root token.

## Before you start

You need to know that OpenBao starts sealed, that key shares rebuild the unseal key, and that any threshold of shares unseals it. You also need `jq` on your machine to read JSON output.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`. The server is installed but **not initialized**, so the pod `openbao-0` shows `0/1`; that is expected. The environment installs the `bao` command-line tool on your machine. Start the port-forward in a second terminal (`kubectl -n openbao port-forward svc/openbao 8200:8200`) and set `export BAO_ADDR=http://openbao.localtest.me:8200`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
