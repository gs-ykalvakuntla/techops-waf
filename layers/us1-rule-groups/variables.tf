variable "rule_actions" {
  description = <<-EOT
    Controls count vs block mode per rule name.
    Allowed values: "count" or "block"

    New rules ALWAYS start as "count" for validation.
    To switch to block: change the value here and open a PR.
    No changes to main.tf are needed when switching modes.

    Example:
      "CUSTOM_XSS"  = "count"   # pending validation
      "CUSTOM_SQLI" = "block"   # validated, switched 2026-08-18
  EOT
  type    = map(string)
  default = {}

  validation {
    condition     = alltrue([for v in values(var.rule_actions) : contains(["count", "block"], v)])
    error_message = "Each rule action must be 'count' or 'block'."
  }
}

variable "env_prefix" {
  description = "Region prefix: us1, us2, or eu — resolves state bucket and layer names"
  type        = string
}

variable "state_region" {
  description = "AWS region for the Terraform state S3 bucket"
  type        = string
}
