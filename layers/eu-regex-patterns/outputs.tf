# Outputs a map: { "XSS_CUSTOM_NEW" = "arn:aws:wafv2:..." }
# Consumed by rule-groups layers via terraform_remote_state
output "pattern_set_arns" {
  description = "Map of pattern set name to ARN for this region"
  value = {
    for name, ps in aws_wafv2_regex_pattern_set.this :
    name => ps.arn
  }
}
