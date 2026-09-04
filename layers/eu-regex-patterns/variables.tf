variable "regex_pattern_sets" {
  description = <<-EOT
    Map of RegexPatternSets to create in this region.
    Key   = pattern set name (must match exactly across US1/US2/EU)
    Value = description + list of regex strings

    To add a new pattern set (new security ticket):
      1. Add an entry here in all 3 regex-patterns/terraform.tfvars
      2. Open a PR — Terraform creates the set in this region with a new ARN
      3. The ARN is automatically passed to rule-groups via remote state

    To modify patterns:
      Update the patterns list here and open a PR.
  EOT
  type = map(object({
    description = string
    patterns    = list(string)
  }))
}
