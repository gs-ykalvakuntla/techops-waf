# ── RegexPatternSets for US1 (us-east-1) ────────────────────────────────────
# US1 is the SOURCE of truth for patterns.
# US2 and EU use the SAME pattern strings — different ARNs auto-generated.
#
# HOW TO ADD A NEW PATTERN SET (from security ticket):
#   1. Get the pattern strings from AWS Console → WAF → RegexPatternSets
#   2. Add an entry below in this file AND in us2/eu terraform.tfvars
#   3. Open a PR — no changes to main.tf needed

regex_pattern_sets = {

  # Jira: SEC-101 | Added: 2026-08-01
  # Source: AWS Console → WAF → RegexPatternSets → XSS_CUSTOM_NEW (us-east-1)
  # TODO: Replace placeholders with actual regex strings from the console
  "XSS_CUSTOM_NEW" = {
    description = "Custom XSS detection patterns"
    patterns = [
      "PLACEHOLDER_PATTERN_1",  # replace with actual regex from console
      "PLACEHOLDER_PATTERN_2"   # replace with actual regex from console
    ]
  }

  # Add future pattern sets here:
  # "SQLI_CUSTOM" = {
  #   description = "Custom SQL injection patterns"
  #   patterns    = ["pattern1", "pattern2"]
  # }
}
