# The admin policy of ats-112-capstone-030. Given in the task; used by
# solution/apply.sh. Full access to every path, but as a normal token that
# can be revoked and expires, unlike the root token.
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
