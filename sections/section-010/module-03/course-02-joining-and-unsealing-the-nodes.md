# Joining And Unsealing The Nodes

After `openbao-0` is initialized and unsealed, the other two pods need two things: to be part of the Raft cluster, and to be unsealed. Both happen without re-initializing.

## Joining

With `retry_join` in the configuration, the second and third pod ask the first to join as soon as it is unsealed. You can also join by hand, from inside the pod:

<!-- astrona:playground:renew -->

```sh
kubectl -n openbao exec openbao-1 -- bao operator raft join http://openbao-0.openbao-internal:8200
```

The answer is `Joined true`. The node starts to copy the Raft log from the leader. A node that joined but is still sealed cannot take part in elections, so it does not yet count toward the quorum.

## Unsealing each node

Each node holds the unseal key only in its own memory, so each node is unsealed on its own. With one key share:

```sh
UNSEAL="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.unseal-key}' | base64 -d)"
for pod in openbao-1 openbao-2; do
  kubectl -n openbao exec "$pod" -- bao operator unseal "$UNSEAL"
done
```

With a threshold of three, you would run the unseal command three times on each node with different shares. A node that restarts later is sealed again and needs the same treatment, which is the reason production clusters use auto-unseal.

The `bao operator unseal` command inside a pod talks to the pod's own listener at `127.0.0.1:8200`, which is why the command in `kubectl exec` needs no address.

## Reading the cluster

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
bao operator raft list-peers
```

The list has three nodes. One is the `leader` and two are `follower`, and each has `Voter` set to `true`. Check the role of each pod with the status command inside it:

```sh
for pod in openbao-0 openbao-1 openbao-2; do
  kubectl -n openbao exec "$pod" -- bao status | grep -E "HA Mode|Active Node Address"
done
```

The leader shows `HA Mode` `active`. The others show `standby` and the address of the active node. The Services follow the same labels: `kubectl -n openbao get pods -L openbao-active` shows which pod carries the label `openbao-active=true`.

A write on the leader reaches the followers through the Raft log, and a write sent to a follower is forwarded. A secret written once is readable from any node, for example with `kubectl exec openbao-2 -- bao kv get` and the token set by `BAO_TOKEN`.

## Your mission: Turn A Single Node Into A Three-Node Cluster

You can now install a cluster, join nodes and unseal them. The graded lab gives you a server that runs as one standalone node and holds a secret. You must change the Helm release into a three-node cluster, keeping the data.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-112-playground-010-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS112.git -c sections/section-010/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-112-lab-010-03
astrona start ats-112-playground-010-03
```
