variable "branch" {
  type    = string
  default = "main"
}

# three entries required
# GitHub sends a different `sub` claim depending on the trigger context.
# The module builds a trust policy using StringLike under the hood,
# so each entry below matches a specific pattern AWS will receive:

#   :ref:refs/heads/main   ← direct push or non-environment workflow_dispatch
#   :environment:dev       ← workflow_dispatch with environment=dev selected
#   :environment:prod      ← workflow_dispatch with environment=prod selected
#
# All three must be present or the OIDC auth fails for that context.
variable "repository" {
  type = list(string)
}

variable "aws_account_id" {
  type = string
}

variable "region" {
  type = string
}

variable "policies" {
  type = list(string)
}
