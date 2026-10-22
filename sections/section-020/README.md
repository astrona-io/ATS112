# Section 020: Configuring The OpenBao Server

An OpenBao server does exactly what its configuration file says: where it listens, where it stores its data, which address it gives to clients. One wrong line can make a server listen on the wrong port, or start on an empty storage folder and look as if all its data were gone. This section teaches the configuration file, how the Helm chart runs it in Kubernetes, and the difference between a real server and a development server.

**Topic covered:** OpenBao server configuration and storage

## What you will learn

- The blocks and settings of a server configuration file: `listener`, `storage "raft"`, `api_addr`, `cluster_addr`, `ui` and `log_level`.
- Why `disable_mlock` no longer exists in OpenBao.
- How the Helm chart turns its values into the configuration file, which environment variables it adds, and why a change needs a pod restart.
- How to check a configuration with `bao operator validate-config`.
- What development mode does, why it is never a real server, and how to move to a real configuration.

## The learning path

The section has one module. Its playground holds an initialized, unsealed server; the lab-only unseal key and root token are in the Secret `openbao-init`.

### 1. Configure An OpenBao Server

1. The Server Configuration File
2. How The Helm Chart Runs The Server, followed by the lab **Repair A Server Configuration**
3. Development Mode Against A Real Server
4. Summary

## Section capstone: Move A Development Server To A Real Configuration

The capstone starts with OpenBao in development mode: in memory, unsealed, with nothing stored. You replace it with a real server that stores its data with Raft and has a complete configuration, then initialize it and store a first secret. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS112.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-112-capstone-020
```
