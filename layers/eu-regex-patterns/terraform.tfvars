# ── RegexPatternSets for EU (eu-central-1) ─────────────────────────────────────
# US1 is the source of truth for pattern strings.
# US2 and EU use the SAME strings — Terraform creates region-specific ARNs.
#
# To add a new pattern set (new security ticket):
#   1. Add an entry here and in us1 + us2 terraform.tfvars (same patterns)
#   2. Open a PR — no main.tf changes needed

regex_pattern_sets = {

  # Jira: SEC-101 | Added: 2026-08-01 | Switched to block: 2026-08-10
  "XSS_CUSTOM_NEW" = {
    description = "Custom XSS detection patterns — matches script injection in headers, body and URI"
    patterns = [
      "(?i)<script[\s\S]*?>",
      "(?i)javascript\s*:",
      "(?i)on(load|click|mouseover|error|focus)\s*=",
      "(?i)<iframe[\s\S]*?>",
      "(?i)document\.(cookie|write|location)"
    ]
  }

  # Jira: SEC-115 | Added: 2026-08-20 | Pending validation
  "SQLI_CUSTOM_NEW" = {
    description = "Custom SQL injection detection patterns — matches common SQLi payloads"
    patterns = [
      "(?i)(union\s+(all\s+)?select)",
      "(?i)(\bor\b\s+\d+\s*=\s*\d+)",
      "(?i)(;\s*(drop|alter|create|truncate)\s+table)",
      "(?i)(insert\s+into\s+\w+\s*\()",
      "(?i)(sleep\s*\(\s*\d+\s*\))"
    ]
  }

}
