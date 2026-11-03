# Reading And Writing Paths

The commands `bao kv put` and `bao secrets enable` are friendly names for requests to paths. The generic commands `bao read`, `bao write`, `bao list` and `bao delete` work on any path of any component. This part shows them, shows how they relate to `bao kv`, and shows why the KV version 2 engine hides a `data/` segment from you.

## Four verbs for every path

The API uses four kinds of operation, and `bao` has one command for each:

| Command | HTTP method | Operation |
| --- | --- | --- |
| `bao read` | `GET` | Read the data at a path |
| `bao write` | `PUT` or `POST` | Create or update the data at a path |
| `bao list` | `LIST` (a `GET` with `?list=true`) | List the names below a path |
| `bao delete` | `DELETE` | Remove the data at a path |

A policy grants capabilities with matching names: `read`, `create`, `update`, `list`, `delete`, plus `sudo` for protected paths and `deny`. A `bao write` is `create` when the path has no data yet and `update` when it has. This is why a policy that grants only `update` cannot create a new secret.

Begin with a path that every server has. Make sure the playground KV engine exists and a secret is stored:

<!-- astrona:playground:renew -->

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
bao secrets enable -path=secret kv-v2
bao kv put secret/app/config username=app api_url=http://inventory.internal:8080
```

If `secret/` already exists, the first command reports that the path is in use, and you can go on. Now read a system path and list another:

```sh
bao read sys/seal-status
bao list sys/policies/acl
```

The first command prints the same fields as `bao status`, because both ask `sys/seal-status`. The second prints the names of the policies; a new server has `default` and `root`.

## Writing data

`bao write` takes the path and the fields. Fields come as `key=value` pairs, as a JSON file with `@`, or as JSON on standard input with `-`:

```sh
bao write sys/policies/acl/example policy='path "secret/data/example/*" { capabilities = ["read"] }'
bao read sys/policies/acl/example
bao delete sys/policies/acl/example
```

The three commands create a policy through its raw API path, read it back, and delete it. The command `bao policy write` does the same with a friendlier name, and a file for the policy text.

A value that starts with `@`, as in `policy=@policy.hcl`, is read from that file. This is easier than quoting a long value on the command line. A lone `@payload.json` argument loads a whole JSON body.

## The data/ segment of KV version 2

The KV version 2 engine stores several versions of each secret. Its API therefore has separate paths for the data, for the metadata and for the other actions. The data of `secret/app/config` is at `secret/data/app/config`, and its metadata is at `secret/metadata/app/config`. The command `bao kv get secret/app/config` adds `data/` for you. The generic command does not:

```sh
bao read secret/data/app/config
bao read secret/metadata/app/config
bao list secret/metadata/app
```

The first command returns the values in `data.data` and the version information in `data.metadata`. Notice that the field is `data` inside `data`: the outer one is the response, and the inner one is the secret. The second command shows the number of versions and the current version. The third lists the names below `app/`; for KV version 2 the list uses the `metadata` path.

This is the most common source of "permission denied" errors in a policy for KV version 2. A rule for `secret/app/*` does not apply to the API path `secret/data/app/*`. The policy must name `secret/data/...` for reads and writes and `secret/metadata/...` for lists.

## Writing to the data path

You can write a secret with the generic command, but the body must have the `data` wrapper:

```sh
bao write secret/data/app/config data='{"username":"app","api_url":"http://inventory.internal:8080","note":"written with bao write"}'
bao kv get secret/app/config
```

A new version appears, and `bao kv get` shows the extra field. The delete operations also differ: `bao delete secret/data/app/config` marks the latest version as deleted, which `bao kv undelete -versions=3 secret/app/config` reverses; `bao kv destroy` removes a version for good; `bao kv metadata delete` removes the secret and all its versions.

You can now use any path with the generic verbs and read the KV paths correctly. The paths all demand a token, and the next part is about making tokens that can use only some of them.

## Common pitfalls

> [!WARNING]
> - **Reading `secret/app/config` with `bao read`.** On KV version 2 the path is `secret/data/app/config`.
> - **Writing a policy for `secret/app/*` and expecting it to work.** Use `secret/data/app/*` and `secret/metadata/app/*`.
> - **Using `bao kv metadata delete` to "delete" a secret.** It removes every version.
