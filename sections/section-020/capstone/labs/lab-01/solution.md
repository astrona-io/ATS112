# Solution: Move A Development Server To A Real Configuration

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: development mode is off and storage is Raft, the server has 3 shares and a threshold of 2 and is unsealed, the configuration has the asked settings, and the token in `lab-answer` reads the secret.

## Step 1: Confirm development mode

Start the port-forward in a second terminal and ask for the seal status:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
curl -s $BAO_ADDR/v1/sys/seal-status
helm get values openbao -n openbao
```

The status reports `storage_type` `inmem`, and the values show `server.dev.enabled: true`. Everything in this server lives in memory.

## Step 2: Write the real configuration

Save this as `openbao-values.yaml`:

```yaml
fullnameOverride: openbao
injector:
  enabled: false
server:
  image:
    tag: "2.7.1"
  standalone:
    enabled: true
    config: |
      ui        = true
      log_level = "warn"

      listener "tcp" {
        tls_disable     = 1
        address         = "[::]:8200"
        cluster_address = "[::]:8201"
      }

      storage "raft" {
        path    = "/openbao/data"
        node_id = "openbao-0"
      }

      api_addr     = "http://openbao.localtest.me:8200"
      cluster_addr = "http://openbao-0.openbao-internal:8201"
  dataStorage:
    enabled: true
    size: 1Gi
ui:
  enabled: true
```

The file leaves out `server.dev`, so development mode goes back to its default, off. Apply it and restart the pod, because the chart uses the `OnDelete` update strategy:

```sh
helm upgrade openbao openbao/openbao --version 0.30.4 -n openbao -f openbao-values.yaml
kubectl -n openbao delete pod openbao-0
```

## Step 3: Initialize and unseal

Start the port-forward again when the new pod runs. The server is now not initialized. Initialize it with 3 shares and a threshold of 2, and keep the output in a file on your machine:

```sh
bao operator init -key-shares=3 -key-threshold=2 -format=json > init.json
```

`init.json` holds the three shares in `unseal_keys_b64` and the root token in `root_token`. Enter two shares:

```sh
bao operator unseal "$(jq -r '.unseal_keys_b64[0]' init.json)"
bao operator unseal "$(jq -r '.unseal_keys_b64[1]' init.json)"
```

After the second share, `Sealed` is `false`. On a real server, each share now goes to a different person, and `init.json` is deleted.

## Step 4: Store the first secret

Sign in with the root token, enable the KV version 2 engine and write the secret:

```sh
export BAO_TOKEN="$(jq -r '.root_token' init.json)"
bao secrets enable -path=secret kv-v2
bao kv put secret/platform/owner team=platform
```

## Step 5: Give the grader a token

Store the token in the Secret the task asks for:

```sh
kubectl -n openbao create secret generic lab-answer --from-literal=token="$BAO_TOKEN"
```

Check the result and send the capstone for grading:

```sh
curl -s $BAO_ADDR/v1/sys/seal-status
astrona submit -c sections/section-020/capstone/labs/lab-01
```

The seal status now reports `storage_type` `raft`, `n` `3` and `t` `2`.

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Write secrets into the development server | They disappear at the next restart, and the grader sees `inmem` storage |
| Set `server.dev.enabled: false` without a configuration | The server has no usable listener and storage settings |
| Skip the pod deletion | The development server keeps running |

## Common mistakes

- Leaving `log_level` or `ui` out of the configuration string.
- Initializing with the default 5 shares and threshold 3 instead of 3 and 2.
- Keeping `init.json` around after the lab; on a real server it holds every key.
