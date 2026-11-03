# Kubernetes Authentication

A pod already has an identity that Kubernetes vouches for: its **service account**, with a signed token mounted in the pod. The Kubernetes auth method lets OpenBao trust that identity, so the pod needs no secret ID delivered by anyone.

## How the login works

1. The pod reads its service account token from its filesystem.
2. The pod sends the token and a role name to `auth/kubernetes/login`.
3. OpenBao sends the token to the Kubernetes TokenReview API, which says whether the token is valid and which service account and namespace it belongs to.
4. OpenBao compares the answer with the role. If the service account name and the namespace match the role, OpenBao returns a token with the policies of the role.

The check in step 3 means OpenBao must call the Kubernetes API. When OpenBao runs in the same cluster, it uses its own service account token for that call. That service account needs the permission to create token reviews, which the cluster role `system:auth-delegator` grants.

## Configure the method

<!-- astrona:playground:renew -->

```sh
bao auth enable kubernetes
bao write auth/kubernetes/config kubernetes_host=https://kubernetes.default.svc
```

With OpenBao inside the cluster, the host is the internal address of the API server. The method then reads the cluster certificate authority and its own token from the pod. For OpenBao outside the cluster, you also set `kubernetes_ca_cert` and `token_reviewer_jwt`.

## Create a role

A role binds one or more service accounts to policies:

```sh
bao write auth/kubernetes/role/inventory \
  bound_service_account_names=inventory \
  bound_service_account_namespaces=clients \
  token_policies=inventory-read \
  token_ttl=15m
```

Only the service account `inventory` in the namespace `clients` can use this role. A `*` in the names or the namespaces allows any value, and gives much wider access. Use it only when you understand the effect.

## Log in from a pod

A pod that runs with that service account can log in with the token that Kubernetes mounted at `/var/run/secrets/kubernetes.io/serviceaccount/token`:

```sh
JWT="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
bao write auth/kubernetes/login role=inventory jwt="$JWT"
```

The response is a token with the policy `inventory-read`. Applications use a client library, or the OpenBao Agent, to log in and renew the token on their own. The login fails with `permission denied` when the service account or the namespace does not match the role, and with an error from the TokenReview call when the reviewer permission is missing.

## When to choose which method

| Caller | Method |
| --- | --- |
| A person | An outside identity provider with OIDC or LDAP; userpass in a lab |
| A pod in a Kubernetes cluster | Kubernetes |
| An application outside Kubernetes | AppRole, or a cloud method when it runs on that cloud |

## Common pitfalls

> [!WARNING]
> - **Using `*` for the service account names and namespaces.** Any pod in the cluster can then take the role.
> - **Forgetting the `system:auth-delegator` binding.** Every login fails at the review step.
> - **Giving the role a long TTL.** The token should live only as long as the application needs between logins.
