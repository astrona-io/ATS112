# Listener TLS And Client Certificates

The playground listener uses plain HTTP. Anyone on the network path can read the tokens and secrets that cross it. A real server encrypts every connection with Transport Layer Security (TLS). This part shows the listener settings that turn TLS on, how to make clients prove who they are with certificates, and how `bao` and the Helm chart are told about it.

## Why the lab turns TLS off

The listener in the playground has `tls_disable = 1`. That setting is fine in a throwaway cluster, because it lets you read requests with `curl` and avoids creating certificates. It is wrong anywhere else. Tokens travel in an HTTP header, and the unseal shares travel in the body of a request. With no TLS, both are readable by anyone who can see the traffic.

## A listener with TLS

To turn TLS on, remove `tls_disable` and name a certificate and a private key. The files must exist on the server's filesystem when it starts:

```hcl
listener "tcp" {
  address       = "[::]:8200"
  tls_cert_file = "/openbao/tls/tls.crt"
  tls_key_file  = "/openbao/tls/tls.key"
  tls_min_version = "tls12"
}
```

The certificate file holds the server certificate and, after it, any intermediate certificates the client needs to build the chain to a trusted authority. The key file holds the private key. `tls_min_version` rejects older protocol versions; `tls12` is the lowest sensible value and `tls13` is allowed when all clients support it.

The address that clients use must match a name in the certificate, in the subject alternative names. A client that connects to `openbao.example.com` fails when the certificate only names `openbao`. Set `api_addr` to an `https://` address as well, because standby nodes and redirects use it.

In Kubernetes, the usual way to provide the files is a Secret of type `kubernetes.io/tls`, mounted into the pod. In the Helm chart, you add the Secret under `server.volumes` and `server.volumeMounts`, and you set `global.tlsDisable` to `false` so the chart's probes and Service use HTTPS. A tool such as cert-manager can create and renew the Secret.

## Client certificates

TLS normally proves the server's identity to the client only. A listener can also require that the client proves its identity with a certificate. This is called mutual TLS (mTLS):

```hcl
listener "tcp" {
  address                            = "[::]:8200"
  tls_cert_file                      = "/openbao/tls/tls.crt"
  tls_key_file                       = "/openbao/tls/tls.key"
  tls_client_ca_file                 = "/openbao/tls/client-ca.crt"
  tls_require_and_verify_client_cert = true
}
```

`tls_client_ca_file` names the certificate authority whose certificates are accepted. With `tls_require_and_verify_client_cert = true`, a client without such a certificate cannot even send a request. The less strict setting `tls_request_client_cert` asks for a certificate but lets clients without one continue; that is the mode used with the certificate auth method, which turns a certificate into a token.

## Telling the bao tool about TLS

The `bao` tool checks the server certificate against the trusted authorities of your machine. When the certificate comes from a private authority, give the tool that authority's certificate:

```sh
export BAO_ADDR=https://openbao.example.com:8200
export BAO_CACERT=/path/to/ca.crt
bao status
```

`BAO_CACERT` names one authority file, and `BAO_CAPATH` names a directory of them. For mutual TLS, `BAO_CLIENT_CERT` and `BAO_CLIENT_KEY` name the client's certificate and key. The variable `BAO_SKIP_VERIFY=true` turns the server check off. Use it only to find out whether a certificate problem is the cause of a failure, never in a script that you keep.

You can see on the playground that the tool reads these variables, even though the server uses HTTP. `bao status` reports the address it used, and `bao status -address=https://127.0.0.1:1` fails with an error about the connection, not about TLS, because nothing listens there:

<!-- astrona:playground:renew -->

```sh
bao status
bao status -address=https://127.0.0.1:1
```

The first command works with `BAO_ADDR`. The second shows that the `-address` option replaces `BAO_ADDR` for one command.

## Other listener settings

A few more settings appear often. `x_forwarded_for_authorized_addrs` lists the proxies whose `X-Forwarded-For` header OpenBao trusts for the client's real address. `proxy_protocol_behavior` accepts the PROXY protocol from a load balancer. `max_request_size` limits the request body, 32 MiB by default. The separate `cluster_address` carries traffic between the nodes of a cluster, and the nodes secure it with their own certificates, which they create themselves.

You now know how to protect the connection between a client and the server. The listener can also expose the numbers a monitoring system needs, which is the next topic.

## Common pitfalls

> [!WARNING]
> - **Using `BAO_SKIP_VERIFY` as a fix.** It hides the problem and removes the protection.
> - **A certificate that does not name the address in `api_addr`.** Clients and standby nodes fail the name check.
> - **Forgetting that the certificate files are read at start.** A renewed certificate needs a reload or a restart to be used.
