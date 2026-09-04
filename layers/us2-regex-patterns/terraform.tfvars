# ── RegexPatternSets for US2 (us-west-2) ────────────────────────────────────
# Keep pattern strings IDENTICAL to us1-regex-patterns/terraform.tfvars
# Terraform creates new sets here with US2-specific ARNs automatically

regex_pattern_sets = {

  # Jira: SEC-101 | Added: 2026-08-01
  "XSS_CUSTOM_NEW" = {
    description = "Custom XSS detection patterns"
    patterns = [
      "PLACEHOLDER_PATTERN_1",
      "PLACEHOLDER_PATTERN_2"
    ]
  }
}
