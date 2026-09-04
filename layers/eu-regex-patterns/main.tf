# ── RegexPatternSets ─────────────────────────────────────────────────────────
# Creates one RegexPatternSet per entry in terraform.tfvars
# Adding a new pattern set = new entry in tfvars only, no main.tf changes needed
resource "aws_wafv2_regex_pattern_set" "this" {
  for_each = var.regex_pattern_sets

  name        = each.key
  description = each.value.description
  scope       = "REGIONAL"

  dynamic "regular_expression" {
    for_each = each.value.patterns
    content {
      regex_string = regular_expression.value
    }
  }

  tags = merge(local.common_tags, {
    Name             = each.key
    CostTagProject   = each.key
    CostResourceType = "wafregexpatternset"
  })
}
