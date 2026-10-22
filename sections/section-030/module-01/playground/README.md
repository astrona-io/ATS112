# Initialize, Unseal And Operate OpenBao — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-112-playground-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A sandbox that installs OpenBao v2.7.1 and a tester pod, then stays running so
you can explore the module's topic. Nothing to submit. Built from the OpenBao
v2.7.1 documentation and not yet run (see the repository `CLAUDE.md`).

## Run it

```sh
astrona run -c .
astrona destroy ats-112-playground-030-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-112-playground-030-01`), not
the config path. `astrona submit` and `astrona test` do not apply.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `bootstrap/` | Helm, the bao CLI, CoreDNS rewrite, tester and OpenBao (`INIT_MODE=sealed`) |
| `manifests/openbao-values.yaml` | Helm values for OpenBao |
| `manifests/lab-start.yaml` | The tester pod |
| `docs/overview.md` | What the environment contains and ideas to try |
