# ── Environment config ────────────────────────────────────────────────────────
env_prefix   = "us1"
state_region = "us-east-1"

# ── Rule Actions ──────────────────────────────────────────────────────────────
# Controls count vs block mode per rule.
# New rules always start as "count" — switch to "block" after security validates.
#
# Switching count → block:
#   Change "count" to "block" here (and us2/eu tfvars) → open PR → merge
#   No changes to main.tf needed.
#
# Format: "RULE_NAME" = "count|block"   # Jira-ID | Added | Switched

rule_actions = {
  "CUSTOM_XSS" = "count"  # SEC-101 | 2026-08-01 | pending validation
}
