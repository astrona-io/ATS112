# Auth Methods And Secrets Engines

So far every client in this section signed in with a token made by hand. Real clients do not receive hand-made tokens. A person logs in with a user name and a password, an application logs in with a role, and a pod logs in with its Kubernetes service account. Each of these is an **auth method**: it checks an identity from outside and returns a token with the policies that belong to that identity. This module covers three auth methods and the transit secrets engine, which encrypts data without storing it.

Keep one sentence in mind: **an auth method turns an outside identity into a token, and a policy decides what that token may do.**

The module has four parts. **How Auth Methods Work, And Userpass** shows the login flow with the simplest method. **AppRole For Applications** covers a role, a role ID and a secret ID; a graded lab follows it. **Kubernetes Authentication** shows how a pod logs in with its service account token. **The Transit Secrets Engine** encrypts and decrypts data with a key that never leaves the server.

## Learning objectives

After this module you can:

- Enable an auth method at a path and write a user or a role to it.
- Log in with `bao login` and `bao write auth/<path>/login`, and read the token that comes back.
- Create an AppRole role with policies and token limits, and deliver its role ID and secret ID.
- Describe how the Kubernetes auth method checks a service account token.
- Create a transit key, encrypt and decrypt data, rotate the key and rewrap data.

## Before you start

You need a server that is initialized and unsealed, the root token, and the policies from the previous module: how to write a policy and create a token.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`. The server is initialized and unsealed. For this lab only, the unseal key and the root token are in the Kubernetes Secret `openbao-init` (keys `unseal-key` and `root-token`); a real installation never keeps them in the cluster.

The environment installs the `bao` command-line tool on your machine. Start the port-forward in a second terminal (`kubectl -n openbao port-forward svc/openbao 8200:8200`) and set `export BAO_ADDR=http://openbao.localtest.me:8200`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
