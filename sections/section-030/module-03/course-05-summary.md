# Summary

An auth method checks an identity from outside and returns a token with the policies of that identity. `bao auth enable` mounts a method below `auth/`, `bao auth list` shows the mounts and their accessors, and the login paths need no token. After login, only the token and its policies matter. Deleting a user stops new logins and does not revoke tokens that exist.

The userpass method stores users in OpenBao and suits labs. AppRole gives an application a role ID and a secret ID; the role sets the policies and the token TTLs, and the secret ID can be limited by TTL and number of uses. The delivery of the secret ID is the weak point, so keep it short-lived and single use. The Kubernetes method trusts the service account token of a pod: OpenBao sends the token to the TokenReview API and compares the service account name and namespace with the role.

The transit engine encrypts data without storing it. Ciphertext starts with `vault:v1:`, where the number is the key version. `rotate` adds a version and keeps old ones, `rewrap` moves ciphertext to the latest version, and `min_decryption_version` retires old versions. Deleting a key loses all its data.

The key facts to remember:

- An auth method turns an outside identity into a token; the policy decides the access.
- AppRole: role ID is the name, secret ID is the credential.
- Kubernetes: bound service account names and namespaces, never `*` unless intended.
- Transit: rotate, do not delete; rewrap before you raise `min_decryption_version`.

Your playground is no longer needed. Remove it:

<!-- astrona:playground:destroy -->
