# Section 030: Initializing, Unsealing And Sealing With bao

Every OpenBao server starts its life with one command, `bao operator init`, and the choices made in that command stay with it for years: how many key shares exist, how many are needed, and who holds the root token. This section is the operator's daily toolkit: initialize a server, unseal it, sign in, store a secret, seal it, and later rotate its keys and retire the root token.

**Topic covered:** The `bao` CLI and seal operations

## What you will learn

- What `bao operator init` creates and how to choose the number of shares and the threshold.
- How to unseal a server, sign in with a token, and enable and use a KV version 2 secrets engine.
- How to seal a server on purpose and what that does.
- How to replace the unseal keys with `bao operator rotate-keys` and rotate the encryption key with `bao operator rotate`.
- Why the root token is revoked after setup, and how `bao operator generate-root` creates a new one when it is needed.

## The learning path

The section has one module. Its playground holds a server that is installed but **not initialized**.

### 1. Initialize, Unseal And Operate OpenBao

1. Initializing A Server
2. Unseal, Sign In, Store A Secret And Seal Again, followed by the lab **Initialize OpenBao And Store A First Secret**
3. Rotating Keys And Retiring The Root Token
4. Summary

## Section capstone: Rotate Unseal Keys And Retire The Root Token

The capstone starts with a server that was set up the quick way: one key share and a root token that is still in use. You replace the single key with five shares and a threshold of three, rotate the encryption key, give administrators a normal token, and revoke the root token. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS112.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-112-capstone-030
```
