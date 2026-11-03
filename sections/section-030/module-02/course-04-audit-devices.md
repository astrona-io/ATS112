# Audit Devices

An **audit device** records every request that reaches the server and every response it sends. Policies decide what a client may do. The audit log shows what clients did. OpenBao has no audit devices enabled after initialization, so until you enable one, nothing records requests.

## Enabling a device

The simplest device writes JSON lines to a file or to standard output. In a container, standard output is the better choice because the cluster collects it with the other pod logs:

<!-- astrona:playground:renew -->

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
bao audit enable file file_path=stdout
bao audit list -detailed
```

`bao audit list` shows the path of the device (`file/`), its type and its options. To write to a file inside the pod instead, use `bao audit enable file file_path=/openbao/audit/audit.log`; the directory must exist and the server must be able to write to it. Other device types are `syslog` and `socket`.

## Reading an entry

Make a request, then read the pod log:

```sh
bao kv put secret/inventory/db username=inventory password=lab-only-1
kubectl -n openbao logs openbao-0 | tail -n 2
```

Each request produces two JSON lines. The entry with `"type":"request"` is written before the server handles the request. The entry with `"type":"response"` is written after. Both hold the `request.path`, the `request.operation`, the `auth` block with the policies of the token, and the remote address. The fields can differ between versions, so read an entry from your own server before you build a tool on it.

## Why values are hashed

The log would be a second copy of every secret if it held them in plain text. By default, OpenBao replaces every string value in the log, including tokens and secret data, with an HMAC-SHA256 hash that starts with `hmac-sha256:`. The same input always gives the same hash for one device, so you can find out whether a value appears in the log without storing the value there. To compute the hash of a value, ask the server:

```sh
bao write sys/audit-hash/file input=lab-only-1
```

The result is the hash that an entry would hold for `lab-only-1`. Search the log for that hash to see which requests carried the value. A device option `log_raw=true` turns hashing off. Do not use it outside a lab, because the log then contains secrets and tokens.

## When the device fails

The server will not process a request unless at least one enabled audit device records it first. If the only device cannot write, because the disk is full or the socket is closed, every request fails with an error and the server is unusable until a device works again. This design means that no action goes unrecorded. Two rules follow from it:

- Enable more than one device on a production server. A request succeeds if at least one device records it.
- Watch the disk and the connection that a device uses, as you do for the storage backend.

## Disabling a device

```sh
bao audit disable file
```

Disabling the last device removes the record of all later requests. Do this only in a lab. In production, a request to disable a device is itself an event you want to see in the log of another device.

> [!WARNING]
> - **Running a production server with no audit device.** No request is recorded, and you cannot answer who read a secret.
> - **Enabling `log_raw=true` for debugging and leaving it.** The log holds plain secrets.
> - **Sending the only device to a full disk.** The server stops answering requests.
