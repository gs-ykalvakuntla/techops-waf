# ── Environment config ────────────────────────────────────────────────────────
env_prefix   = "eu"
state_region = "eu-central-1"

# ── Rule Actions ──────────────────────────────────────────────────────────────
rule_actions = {
  "CUSTOM_XSS"  = "block"   # SEC-101 | Added: 2026-08-01 | Switched to block: 2026-08-10
  "CUSTOM_SQLI" = "count"   # SEC-115 | Added: 2026-08-20 | Pending validation
}
