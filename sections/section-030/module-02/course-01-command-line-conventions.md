# Command-Line Conventions

The `bao` tool is a client for the HTTP API. It adds no new ability to the server. It builds requests, sends them, and prints the answers. Once you know how it finds the server, how it sends a token, and how it prints results, you can use every command, including the ones this course never shows.

## Which server, which token

Three pieces of information go into every request: the address of the server, the token, and an optional namespace. The tool takes each from an environment variable or from an option, and the option wins:

| Setting | Environment variable | Option |
| --- | --- | --- |
| Server address | `BAO_ADDR` | `-address` |
| Token | `BAO_TOKEN` | none (use `bao login`) |
| Namespace | `BAO_NAMESPACE` | `-namespace` |
| Output format | `BAO_FORMAT` | `-format` |

A **namespace** is a separate area inside one server, with its own mounts, policies and tokens. Most installations in this course use only the root namespace. The address defaults to `https://127.0.0.1:8200` if nothing is set, which is why a missing `BAO_ADDR` usually shows up as a connection error to that address.

If `BAO_TOKEN` is not set, the tool reads the token that `bao login` stored in the file `~/.bao-token`. This file is the **token helper** storage. Setting `BAO_TOKEN` is the safer choice in scripts, because it leaves nothing on disk.

Set the playground up and check the tool:

<!-- astrona:playground:renew -->

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
bao version
bao status
bao token lookup
```

`bao version` prints the tool's version. `bao token lookup` shows the details of the token in use: its `policies`, its `ttl` and its `type`. The root token's TTL is `0`, which means it never expires.

## Output formats

Commands print a table by default, made for people. For scripts, ask for JSON with `-format=json` or set `BAO_FORMAT=json`. A second option, `-field`, prints a single field as plain text with no extra line:

```sh
bao token lookup -format=json
bao token lookup -field=policies
```

Scripts should parse JSON with a tool such as `jq`, and use `-field` when they need one value. A script that cuts the table output with `awk` breaks when the table layout changes.

## Exit codes

A command that works exits with `0`. A command that fails exits with `1`, and `bao status` uses `2` for a server that is sealed or not initialized, so a script can tell "sealed" from "not reachable". The health checks of the Helm chart rely on this.

```sh
bao status > /dev/null; echo "exit code $?"
```

## See the request behind a command

Two options help you understand what a command does. `-output-curl-string` does not send the request. It prints the `curl` command that would send it, with the token hidden by a placeholder variable:

```sh
bao kv get -output-curl-string secret/app/config
```

The printed command shows the real path, `/v1/secret/data/app/config`, and the method. `-output-policy` prints the policy that would allow the command, which helps when you write a policy for a new application. Both options work on any command.

```sh
bao kv get -output-policy secret/app/config
```

## Help and completion

`bao <command> -h` prints the options of a command. `bao path-help <path>` asks the server what the component at a path accepts, with the fields it takes and what they mean:

```sh
bao path-help sys/mounts
```

This is the main way to learn a secrets engine or an auth method that this course does not cover. `bao -autocomplete-install` adds tab completion to your shell.

You can now point `bao` at a server and see exactly which request it sends. The next step is to use it on paths directly.

## Common pitfalls

> [!WARNING]
> - **Leaving an old `BAO_TOKEN` in the shell.** It overrides the token stored by `bao login`, and you act as the old token.
> - **Parsing the table output in a script.** Use `-format=json` or `-field`.
> - **Pasting the output of `-output-curl-string` with a real token into a ticket.** The placeholder is safe; a real token in a command line is not.
