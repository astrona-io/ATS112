# Daily Work With The bao Command-Line Tool

Initializing and unsealing happen a few times in the life of a server. Reading and writing secrets, issuing tokens, writing policies and checking the audit log happen every day. This module covers the habits and commands of that daily work, from the environment variables that point `bao` at a server to the audit devices that record what it does.

Keep one sentence in mind: **every `bao` command is an HTTP request to a path, and a token with the right policy decides whether it works.**

The module has four parts. **Command-Line Conventions** covers the environment variables, the output formats and the options that every command shares. **Reading And Writing Paths** shows the generic commands that work on any path and how they differ from `bao kv`. **Tokens And Policies** creates a policy and a token that can use only what the policy allows; a graded lab follows it. **Audit Devices** turns on the log that records every request.

## Learning objectives

After this module you can:

- Point `bao` at a server and a token with environment variables, and choose an output format.
- Use `bao read`, `bao write`, `bao list` and `bao delete` on any path, and `bao path-help` to learn a path.
- Show the HTTP request behind a command with `-output-curl-string`.
- Write a policy in HCL, create a token with it, and test what the token may do with `bao token capabilities`.
- Read a token with `bao token lookup`, and renew or revoke it.
- Enable a file audit device and explain why values in the log are hashed.

## Before you start

You need a server that is initialized and unsealed, and the root token. You should know how to enable a KV version 2 engine and write a secret.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`. The server is initialized with a single key share and unsealed. For this lab only, the unseal key and the root token are in the Kubernetes Secret `openbao-init` (keys `unseal-key` and `root-token`); a real installation never keeps them in the cluster.

The environment installs the `bao` command-line tool on your machine. Start the port-forward in a second terminal (`kubectl -n openbao port-forward svc/openbao 8200:8200`) and set `export BAO_ADDR=http://openbao.localtest.me:8200`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
