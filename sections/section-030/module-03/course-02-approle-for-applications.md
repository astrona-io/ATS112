# AppRole For Applications

An application has no person to type a password. The **AppRole** method gives it two values that work together: a **role ID** and a **secret ID**. The role ID names the role and is not secret by itself, like a user name. The secret ID is the credential, like a password, and it can be limited to a short life or a single use. Two values let two systems share the work: the platform that deploys the application knows the role ID, and a trusted delivery step hands over the secret ID at start time.

## Enable the method and create a role

<!-- astrona:playground:renew -->

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
bao auth enable approle
bao write auth/approle/role/inventory-app \
  token_policies=inventory-read \
  token_ttl=15m \
  token_max_ttl=1h \
  secret_id_ttl=24h \
  secret_id_num_uses=0
```

The role needs a policy named `inventory-read`; write it first if your playground does not have it. The settings:

- `token_policies` is the list of policies of every token the role creates.
- `token_ttl` and `token_max_ttl` set the life of those tokens.
- `secret_id_ttl` is how long a secret ID works after it is created; `0` means no limit.
- `secret_id_num_uses` is how many logins one secret ID allows; `0` means no limit. A value of `1` makes a secret ID usable once, which is the safer setting for production.

## Read the role ID and create a secret ID

```sh
bao read -field=role_id auth/approle/role/inventory-app/role-id
bao write -f -field=secret_id auth/approle/role/inventory-app/secret-id
```

The first command prints the role ID, which stays the same. The second creates a new secret ID on every call; `-f` sends an empty request, because the path needs no input. OpenBao shows the secret ID only in this response. Store both values where the application can read them, such as a Kubernetes Secret.

## Log in

```sh
bao write auth/approle/login role_id="$ROLE_ID" secret_id="$SECRET_ID"
```

The response holds the token with the policy `inventory-read` and a lease of 900 seconds. The application uses the token until it expires, then logs in again with the same pair. If `secret_id_num_uses` is `1`, a second login with the same secret ID fails, and the delivery step must create a new one.

## Delivering the secret ID safely

The weak point of AppRole is the delivery of the secret ID. Two practices help:

- Keep the life of a secret ID short and make it single use, so a leaked value is already spent.
- Let a trusted component create the secret ID and give it only to the application it was made for. The component needs a policy that allows `update` on `auth/approle/role/inventory-app/secret-id` and nothing else.

Wrapping the response, with `-wrap-ttl=60s`, puts the secret ID inside a single-use wrapping token, so the component never sees the value itself.

## Common pitfalls

> [!WARNING]
> - **Storing the role ID and the secret ID together.** Whoever reads that place can log in. Deliver them by separate routes.
> - **Using one secret ID for every copy of an application.** One leak affects every copy, and you cannot tell the copies apart in the audit log.
> - **Setting no TTL on the secret ID.** An old secret ID stays valid for ever.

## Your mission: Give An Application An AppRole Login

You can now create an AppRole role, read its role ID and create a secret ID. The graded lab gives you a server with two secrets in different folders and the policy `inventory-read`. You must create the role and hand its login values to the application.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-112-playground-030-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS112.git -c sections/section-030/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-112-lab-030-03
astrona start ats-112-playground-030-03
```
