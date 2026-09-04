# ── Environment config ────────────────────────────────────────────────────────
env_prefix   = "us2"
state_region = "us-west-2"

# ── Rule Actions ──────────────────────────────────────────────────────────────
# One entry per rule. This is the ONLY file you change to switch count → block.
#
# Format:
#   "RULE_NAME" = "count|block"  # Jira-ID | Added | Switched to block
#
# Rules always start as "count" for security team validation.
# After validation, change "count" → "block" here (and us2/eu) and open a PR.
# No changes to main.tf are needed when switching modes.
#
# RULE_NAME must exactly match the name field in the rule {} block in main.tf

rule_actions = {
  "CUSTOM_XSS"  = "count"   # SEC-101 | 2026-08-01 | pending validation

  # Add the next rule here when the ticket arrives:
  # "CUSTOM_SQLI" = "count"  # SEC-115 | <date>    | pending validation
  # "CUSTOM_RCE"  = "count"  # SEC-122 | <date>    | pending validation
}
