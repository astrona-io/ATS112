---
estimated_duration: 30m
---

# Unseal A Server When One Key Share Is Wrong

- **ID:** CAPSTONE
- **Slug:** ats-112-capstone-010
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for OpenBao in the namespace `openbao`. Read `question.md` for the task; `solution.md` is the walkthrough.
Built from the OpenBao v2.7.1 documentation and source, and not yet run (see the repository `CLAUDE.md`).

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-112-capstone-010
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-112-capstone-010`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/01-install-openbao.sh` | Helm, the bao CLI, the CoreDNS rewrite, tester and OpenBao |
| `bootstrap/02-seed-state.sh` | The starting state of the task |
| `manifests/` | Helm values and the tester pod |
| `solution/apply.sh` | Reference solution used by `astrona test` |
| `testing/wait-for-openbao.sh` | Waits until OpenBao answers |
| `validation/` | Grading scripts, one per check |
