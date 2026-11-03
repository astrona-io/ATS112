# Summary

This module covered the daily work with the `bao` command-line tool.

- Every `bao` command is an HTTP request. `BAO_ADDR` and `BAO_TOKEN` point it at a server and a token, `-format=json` makes output readable by scripts, and `-output-curl-string` shows the request.
- `bao read`, `bao write`, `bao list` and `bao delete` work on any path. For a KV version 2 engine, the paths hold `data/` and `metadata/` segments that `bao kv` adds for you. `bao path-help` describes a path.
- A policy lists paths and the capabilities allowed on each. Anything not allowed is denied, and `deny` overrides every other rule.
- `bao token create` makes a token with policies and a TTL. `bao token capabilities` tests a path, `bao token lookup` shows a token, and `bao token revoke` ends it and its children.
- An audit device records every request and response. Values are hashed with HMAC-SHA256, and a server without a working audit device refuses requests.

You now have what you need to give a client the least access it requires, and to prove what it did.

Your playground is no longer needed. Remove it:

<!-- astrona:playground:destroy -->
