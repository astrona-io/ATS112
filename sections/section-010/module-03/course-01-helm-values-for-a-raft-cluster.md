# Helm Values For A Raft Cluster

The chart runs OpenBao as a StatefulSet. In standalone mode it has one pod. In high-availability mode with Raft it has the number of pods you ask for, and each pod has its own persistent volume for its Raft data.

## The values

```yaml
fullnameOverride: openbao
injector:
  enabled: false
server:
  image:
    tag: "2.7.1"
  ha:
    enabled: true
    replicas: 3
    raft:
      enabled: true
      setNodeId: true
      config: |
        ui = true
        listener "tcp" {
          tls_disable     = 1
          address         = "[::]:8200"
          cluster_address = "[::]:8201"
        }
        storage "raft" {
          path = "/openbao/data"
          retry_join {
            leader_api_addr = "http://openbao-0.openbao-internal:8200"
          }
          retry_join {
            leader_api_addr = "http://openbao-1.openbao-internal:8200"
          }
          retry_join {
            leader_api_addr = "http://openbao-2.openbao-internal:8200"
          }
        }
        api_addr     = "http://openbao.localtest.me:8200"
        cluster_addr = "http://$(HOSTNAME).openbao-internal:8201"
        service_registration "kubernetes" {}
  dataStorage:
    enabled: true
    size: 1Gi
ui:
  enabled: true
```

Compare it with the standalone values:

- `server.standalone.enabled` is replaced by `server.ha.enabled` and `server.ha.raft.enabled`.
- `replicas: 3` creates three pods.
- `setNodeId: true` makes the chart set the node ID from the pod name, so the nodes are `openbao-0`, `openbao-1` and `openbao-2`. Each node needs a different ID, and a fixed `node_id` in the shared configuration would give them all the same one.
- Each `retry_join` block names a node that may already be in the cluster. A starting node tries them in turn until one answers, and then joins.
- `cluster_addr` uses the pod's own name, so the other nodes can reach it on port 8201. The chart replaces the host name when the pod starts.
- `service_registration "kubernetes"` makes OpenBao label each pod as active or standby. The Service `openbao-active` then points at the active pod, and `openbao-standby` at the others.

The `api_addr` here is a single address for the whole cluster, as in the other labs of this course. A production cluster gives each node its own `api_addr`, so that redirects and request forwarding reach the right pod.

## Install

<!-- astrona:playground:renew -->

```sh
helm upgrade --install openbao openbao/openbao --version 0.30.4 -n openbao --create-namespace -f openbao-values.yaml
kubectl -n openbao get pods
```

All three pods start. None is Ready, because none is initialized yet. The StatefulSet starts pods in order, and the next pod starts when the previous one is Running, not Ready (the chart sets parallel pod management for this reason).

## Initialize only one node

Initialization happens once for the cluster, on one node. Use `openbao-0`:

```sh
kubectl -n openbao exec openbao-0 -- bao operator init -key-shares=1 -key-threshold=1 -format=json
```

The other nodes read the cluster's keys from the leader when they join, so they are not initialized with a command. Save the unseal key and the root token as in the previous sections. One share is for the lab; a real cluster uses five shares and a threshold of three.

## Common pitfalls

> [!WARNING]
> - **Initializing each pod.** Every `init` makes a separate cluster. Initialize one pod.
> - **Setting the same `node_id` on every pod.** Nodes with the same ID overwrite each other in the Raft configuration.
> - **Using two replicas.** Two nodes have a quorum of two, so they tolerate no failure. Use three or five.
