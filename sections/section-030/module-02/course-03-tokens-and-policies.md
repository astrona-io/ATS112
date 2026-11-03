# Tokens And Policies

The root token can do everything, and the course has already shown how to retire it. Every other credential in OpenBao is a token with a policy. A **policy** is a list of paths with the capabilities allowed on each. A **token** is a string that a client sends with every request, and the server looks up the policies attached to it. This part writes a policy, creates a token with it and tests what the token can and cannot do.

## Writing a policy

A policy is a document in HCL (HashiCorp Configuration Language) that holds `path` rules. Each rule names a path and a list of capabilities. OpenBao denies everything that no rule allows. Save this as `policy-inventory-read.hcl`:

```hcl
path "secret/data/inventory/*" {
  capabilities = ["read"]
}

path "secret/metadata/inventory/*" {
  capabilities = ["read", "list"]
}
```

The first rule lets a token read secrets stored below `inventory/`. The second lets it list the names and read the metadata. The `*` at the end of a path matches any text after it, including more slashes. A `+` matches exactly one path segment, so `secret/data/+/db` matches `secret/data/inventory/db` and `secret/data/billing/db`, but not `secret/data/a/b/db`.

Set up the playground with two secrets in different folders, then write the policy:

<!-- astrona:playground:renew -->

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
bao secrets enable -path=secret kv-v2
bao kv put secret/inventory/db username=inventory password=lab-only-1
bao kv put secret/billing/db username=billing password=lab-only-2
bao policy write inventory-read policy-inventory-read.hcl
bao policy read inventory-read
```

If the KV engine already exists, the first command reports an error and you can go on. `bao policy read` prints the text back.

When a path matches several rules, the most specific rule wins. The capability `deny` overrides every other rule for a path, so it is the way to carve an exception out of a wide rule. A policy named `default` is attached to every token unless you ask otherwise; it lets a token look up and renew itself.

## Creating a token

`bao token create` makes a new token. The options set what it can do and how long it lives:

```sh
bao token create -policy=inventory-read -ttl=1h -display-name=inventory-reader -format=json > token.json
```

The JSON holds the token in `auth.client_token`, the policies in `auth.policies` (`inventory-read` and `default`), and the lease duration in seconds. The token is a child of the root token, and it is valid for one hour. Other useful options: `-renewable=false` makes it non-renewable, `-use-limit=5` ends it after five requests, `-orphan` removes the parent link, and `-no-default-policy` leaves the `default` policy off.

A token has a **time to live** (TTL). When it ends, the token stops working. A renewable token can be renewed with `bao token renew` up to its maximum TTL. Short-lived tokens limit the damage of a leak. Production applications normally do not hold tokens from `token create`; they log in with an auth method and receive a token that expires.

## Testing what a token can do

Do not guess. Ask the server, with the token you made:

```sh
export APP_TOKEN="$(jq -r '.auth.client_token' token.json)"
bao token capabilities "$APP_TOKEN" secret/data/inventory/db
bao token capabilities "$APP_TOKEN" secret/data/billing/db
```

The first command prints `read`. The second prints `deny`, because no rule of the policy matches `billing`. The real request gives the same result. Switch to the new token and try:

```sh
BAO_TOKEN="$APP_TOKEN" bao kv get secret/inventory/db
BAO_TOKEN="$APP_TOKEN" bao kv get secret/billing/db
BAO_TOKEN="$APP_TOKEN" bao kv put secret/inventory/db password=changed
```

The first command works. The second and the third fail with a `403` and the message `permission denied`. The third fails because the policy has `read` only, with no `create` or `update`. An error `permission denied` after a correct policy usually means a path that is a little different from the rule, for example `secret/inventory/db` instead of `secret/data/inventory/db`; `-output-policy` on the failing command prints the rule that it needs.

## Looking up, renewing and revoking

```sh
bao token lookup "$APP_TOKEN"
bao token renew "$APP_TOKEN"
bao token revoke "$APP_TOKEN"
```

`lookup` shows the policies, the remaining `ttl` and whether the token can be renewed. `renew` extends the lease. `revoke` ends the token and, because revocation follows the parent link, every child token it created. Revocation takes effect at once on every node.

You can now give a client exactly the access it needs and prove it. The graded lab asks you to build such a token for the inventory application on a server where you must not use the root token for the application.

## Common pitfalls

> [!WARNING]
> - **Writing the policy for the logical path of a KV version 2 secret.** Use `secret/data/...` and `secret/metadata/...`.
> - **Giving an application the `root` policy because a rule was hard to write.** Use `-output-policy` to find the rule.
> - **Creating tokens with a long TTL for convenience.** A leaked token is valid until it expires.

## Your mission: Create A Read-Only Policy And Token

You can now write a policy, create a token with it and test it. The graded lab gives you a server with two secrets in different folders, and asks you to create a policy and a token for the inventory application that can read one folder and nothing else.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-112-playground-030-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS112.git -c sections/section-030/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-112-lab-030-02
astrona start ats-112-playground-030-02
```
