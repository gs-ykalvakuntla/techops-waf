# ── Remote State — reads pattern set ARNs from regex-patterns layer ──────────
data "terraform_remote_state" "regex_patterns" {
  backend = "s3"
  config = {
    bucket = "${var.env_prefix}-waf-tfstate"
    key    = "${var.env_prefix}-regex-patterns/terraform.tfstate"
    region = var.state_region
  }
}

locals {
  # Map of pattern set name → ARN for this region.
  # Usage: local.ps["XSS_CUSTOM_NEW"] resolves to the correct ARN per region.
  # No hardcoded ARNs anywhere — name lookup handles US1 / US2 / EU.
  ps = data.terraform_remote_state.regex_patterns.outputs.pattern_set_arns
}

# ── Rule Group: gainsight-rules-global ───────────────────────────────────────
# One rule group per region, attached to ALL WAF ACLs via the one-time script.
# All custom security rules from security team Jira tickets live here.
#
# Adding a new rule:
#   1. Add pattern set to *-regex-patterns/terraform.tfvars (if new set needed)
#   2. Add "RULE_NAME" = "count" to *-rule-groups/terraform.tfvars
#   3. Add a rule {} block below (copy CUSTOM_SQLI as template)
#   4. Open one PR across all 3 regions
#
# Switching count → block (after security team validates):
#   Only edit terraform.tfvars — change "count" to "block". No main.tf change.
#
# Capacity = total WCU of all rules. Recalculate when adding rules.
# WCU ref: https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statements-list.html
resource "aws_wafv2_rule_group" "custom_security" {
  name        = "gainsight-rules-global"
  description = "All custom security rules — managed by Terraform. Do not edit in console."
  scope       = "REGIONAL"
  capacity    = 300

  # ── RULE: CUSTOM_XSS ────────────────────────────────────────────────────────
  # Jira    : SEC-101
  # Added   : 2026-08-01 (count mode)
  # Switched: 2026-08-10 (block mode — validated by security team)
  # Matches : XSS payloads in query args, JSON body, URI path
  rule {
    name     = "CUSTOM_XSS"
    priority = 1

    dynamic "action" {
      for_each = [lookup(var.rule_actions, "CUSTOM_XSS", "count")]
      content {
        dynamic "count" {
          for_each = action.value == "count" ? [1] : []
          content {}
        }
        dynamic "block" {
          for_each = action.value == "block" ? [1] : []
          content {
            custom_response { response_code = 410 }
          }
        }
      }
    }

    statement {
      or_statement {
        statement {
          regex_pattern_set_reference_statement {
            arn = local.ps["XSS_CUSTOM_NEW"]
            field_to_match { all_query_arguments {} }
            text_transformation {
              priority = 0
              type     = "URL_DECODE_UNI"
            }
          }
        }
        statement {
          regex_pattern_set_reference_statement {
            arn = local.ps["XSS_CUSTOM_NEW"]
            field_to_match {
              json_body {
                match_pattern { all {} }
                match_scope       = "ALL"
                oversize_handling = "CONTINUE"
              }
            }
            text_transformation {
              priority = 0
              type     = "URL_DECODE_UNI"
            }
          }
        }
        statement {
          regex_pattern_set_reference_statement {
            arn = local.ps["XSS_CUSTOM_NEW"]
            field_to_match { uri_path {} }
            text_transformation {
              priority = 0
              type     = "URL_DECODE_UNI"
            }
          }
        }
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "CUSTOM_XSS"
    }
  }

  # ── RULE: CUSTOM_SQLI ───────────────────────────────────────────────────────
  # Jira    : SEC-115
  # Added   : 2026-08-20 (count mode — pending validation by security team)
  # Matches : SQL injection payloads in query args, JSON body, URI path
  rule {
    name     = "CUSTOM_SQLI"
    priority = 2

    dynamic "action" {
      for_each = [lookup(var.rule_actions, "CUSTOM_SQLI", "count")]
      content {
        dynamic "count" {
          for_each = action.value == "count" ? [1] : []
          content {}
        }
        dynamic "block" {
          for_each = action.value == "block" ? [1] : []
          content {
            custom_response { response_code = 410 }
          }
        }
      }
    }

    statement {
      or_statement {
        statement {
          regex_pattern_set_reference_statement {
            arn = local.ps["SQLI_CUSTOM_NEW"]
            field_to_match { all_query_arguments {} }
            text_transformation {
              priority = 0
              type     = "URL_DECODE_UNI"
            }
          }
        }
        statement {
          regex_pattern_set_reference_statement {
            arn = local.ps["SQLI_CUSTOM_NEW"]
            field_to_match {
              json_body {
                match_pattern { all {} }
                match_scope       = "ALL"
                oversize_handling = "CONTINUE"
              }
            }
            text_transformation {
              priority = 0
              type     = "URL_DECODE_UNI"
            }
          }
        }
        statement {
          regex_pattern_set_reference_statement {
            arn = local.ps["SQLI_CUSTOM_NEW"]
            field_to_match { uri_path {} }
            text_transformation {
              priority = 0
              type     = "URL_DECODE_UNI"
            }
          }
        }
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "CUSTOM_SQLI"
    }
  }

  # ── ADD NEXT RULE HERE ───────────────────────────────────────────────────────
  # When next security ticket arrives, copy CUSTOM_SQLI block above.
  # Update: name, priority (increment), local.ps["NEW_PATTERN_SET_NAME"]
  # Add to terraform.tfvars: "NEW_RULE_NAME" = "count"

  visibility_config {
    sampled_requests_enabled   = true
    cloudwatch_metrics_enabled = true
    metric_name                = "gainsight-rules-global"
  }

  tags = merge(local.common_tags, {
    Name             = "gainsight-rules-global"
    CostTagProject   = "gainsight-rules-global"
    CostResourceType = "wafrulegroup"
  })
}
