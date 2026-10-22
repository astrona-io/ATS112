# Configure An OpenBao Server

Every OpenBao server reads one configuration file when it starts. The file says where the server listens, where it keeps its data, and which address it gives to clients and to other servers. A server that starts with a wrong file may not start at all, or worse, it may start fine on an empty storage folder.

This module teaches that file and the way Kubernetes runs it. Keep one sentence in mind: **the configuration is read once, at start, so a change only counts after a restart.**

The module has three parts. **The Server Configuration File** goes through the blocks and settings of a real configuration. **How The Helm Chart Runs The Server** shows where the chart puts that file, what it adds, and why the pod must be deleted after a change; a graded lab follows it. **Development Mode Against A Real Server** shows what development mode does and why you never run it for real data.

## Learning objectives

After this module you can:

- Write a `listener "tcp"` block and a `storage "raft"` block.
- Explain `api_addr` and `cluster_addr`, and the environment variables that can set them.
- Find the configuration the chart gives a running pod, and change it through Helm values.
- Restart OpenBao after a configuration change when the chart uses the `OnDelete` update strategy.
- Check a configuration with `bao operator validate-config`.
- Tell a development server from a real one.

## Before you start

You need Kubernetes and Helm basics: `kubectl get`, `kubectl exec`, `helm get values` and `helm upgrade`. You should know that OpenBao starts sealed and is unsealed with key shares.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, installed with the `openbao` Helm chart 0.30.4. The server is initialized with a single key share and unsealed. For this lab only, the unseal key and the root token are in the Kubernetes Secret `openbao-init` (keys `unseal-key` and `root-token`); a real installation never keeps them in the cluster.

The environment installs Helm and the `bao` command-line tool on your machine. Start the port-forward in a second terminal (`kubectl -n openbao port-forward svc/openbao 8200:8200`) and set `export BAO_ADDR=http://openbao.localtest.me:8200`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
