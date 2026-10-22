# Solution: Unseal A Server When One Key Share Is Wrong

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: the server is unsealed with 5 shares and a threshold of 3, it is the original cluster with the original encryption key, `secret/ops/bad-share` names the wrong share, and `/v1/sys/health` answers `200`.

## Step 1: See what a wrong share does

Start the port-forward in a second terminal, set the address and define the helpers:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
share() {
  kubectl -n openbao get secret openbao-shares -o jsonpath="{.data.share-$1}" | base64 -d
}
```

Try shares 1, 2 and 3:

```sh
bao operator unseal "$(share 1)"
bao operator unseal "$(share 2)"
bao operator unseal "$(share 3)"
```

If one of these three is the wrong share, the third call fails: OpenBao combined three shares into a key that cannot decrypt the root key, so it reports an error and the server stays sealed. The share values look normal; OpenBao can only tell that a share is wrong when the threshold is reached and the rebuilt key does not work. If all three are good, the server unseals; then seal it again for the next step (`bao operator seal`, with the root token in `BAO_TOKEN`).

## Step 2: Find a combination that works

Reset the progress before each attempt, so that shares from a failed attempt do not mix with the next one. A helper does the reset and enters three shares:

```sh
try_shares() {
  bao operator unseal -reset >/dev/null
  for number in "$@"; do bao operator unseal "$(share "$number")" >/dev/null 2>&1; done
  bao status >/dev/null; echo "shares $*: exit code $?"
}
try_shares 1 2 3
try_shares 1 4 5
```

Exit code `0` means the combination unsealed the server, `2` means it is still sealed. With one wrong share among five, any combination that leaves it out works. Note the first combination that works; its three shares are all good.

## Step 3: Test the remaining shares one by one

Sign in with the root token so you can seal between tests:

```sh
export BAO_TOKEN="$(kubectl -n openbao get secret openbao-root -o jsonpath='{.data.root-token}' | base64 -d)"
```

For each share outside the working combination, seal the server and try it together with two shares you know are good. For example, if 1, 4 and 5 worked, test share 2 with shares 1 and 4, then share 3 with shares 1 and 4:

```sh
bao operator seal
try_shares 1 4 2
bao operator seal
try_shares 1 4 3
```

The combination with the wrong share leaves the server sealed. The other one unseals it. If the server is sealed after your last test, unseal it with the working combination.

## Step 4: Record the wrong share and check health

Write the name of the wrong share, for example if share 2 failed:

```sh
bao kv put secret/ops/bad-share name=share-2
```

Then ask the health endpoint from inside the cluster, as a probe would:

```sh
kubectl -n clients exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}\n' http://openbao.localtest.me:8200/v1/sys/health
```

It answers `200`. Send the capstone for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Initialize the server again | It is already initialized; on new storage you would lose every secret, and the grader sees a new cluster ID |
| Guess the name of the wrong share | The grader compares it with the share the seed damaged |
| Leave the server sealed after the last test | The unseal check fails and so does the health check (`503`) |

## Common mistakes

- Not resetting between attempts, so a share from a failed attempt counts towards the next one.
- Sealing while the server is already sealed: `bao operator seal` then fails, which is harmless.
- Reading a failed unseal as "the server is broken". The server is fine; one share is not.
