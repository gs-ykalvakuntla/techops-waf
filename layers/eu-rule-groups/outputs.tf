output "rule_group_arn" {
  description = "ARN of gainsight-rules-global — use this in the associate-rule-group.sh script"
  value       = aws_wafv2_rule_group.custom_security.arn
}

output "rule_group_id" {
  description = "ID of gainsight-rules-global"
  value       = aws_wafv2_rule_group.custom_security.id
}
