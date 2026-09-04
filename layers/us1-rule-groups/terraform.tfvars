# ── Environment config ────────────────────────────────────────────────────────
env_prefix   = "us1"
state_region = "us-east-1"

# ── Rule Actions ──────────────────────────────────────────────────────────────
# Controls count vs block mode per rule.
# New rules always start as "count" for security team validation.
# To switch count → block: change the value here (and us2/eu) and open a PR.
# No changes to main.tf are needed when switching modes.

rule_actions = {
  "CUSTOM_XSS"  = "block"   # SEC-101 | Added: 2026-08-01 | Switched to block: 2026-08-10
  "CUSTOM_SQLI" = "count"   # SEC-115 | Added: 2026-08-20 | Pending validation
}
