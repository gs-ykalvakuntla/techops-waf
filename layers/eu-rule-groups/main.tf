# ── Remote State — reads pattern set ARNs from regex-patterns layer ──────────
# ARNs are region-specific and automatically resolved per environment
data "terraform_remote_state" "regex_patterns" {
  backend = "s3"
  config = {
    bucket = "${var.env_prefix}-waf-tfstate"
    key    = "${var.env_prefix}-regex-patterns/terraform.tfstate"
    region = var.state_region
  }
}

locals {
  # Map of pattern set name → ARN for this region
  # Usage: local.ps["XSS_CUSTOM_NEW"] → correct region ARN automatically
  # No hardcoded ARNs — name lookup handles all 3 regions
  ps = data.terraform_remote_state.regex_patterns.outputs.pattern_set_arns
}

# ── Rule Group: gainsight-rules-global ───────────────────────────────────────
# Attached to ALL WAF ACLs in this region via the one-time association script.
# All custom security rules from the security team live here.
#
# TO ADD A NEW RULE (new security ticket):
#   1. Add pattern set to terraform.tfvars in regex-patterns layer (if needed)
#   2. Add rule_actions entry in terraform.tfvars: "NEW_RULE" = "count"
#   3. Add a rule {} block below following the CUSTOM_XSS example
#   4. Open a PR
#
# TO SWITCH COUNT → BLOCK:
#   Only change terraform.tfvars: "RULE_NAME" = "block"
#   No changes to this file needed.
#
# CAPACITY: Sum of WCU for all rules. Update when adding rules.
# WCU ref: https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statements-list.html
resource "aws_wafv2_rule_group" "custom_security" {
  name        = "gainsight-rules-global"
  description = "All custom security rules — managed by Terraform. Do not edit manually in console."
  scope       = "REGIONAL"
  capacity    = 200 # TODO: recalculate after adding more rules

  # ── RULE: CUSTOM_XSS ────────────────────────────────────────────────────────
  # Jira: SEC-101 | Added: 2026-08-01
  # Matches XSS patterns in: query arguments, JSON body, URI path
  # Action controlled by terraform.tfvars → rule_actions["CUSTOM_XSS"]
  rule {
    name     = "CUSTOM_XSS"
    priority = 22

    # Dynamic action: switches between count and block based on tfvars
    # Default: "count" (safe fallback if not specified in tfvars)
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
        # Match 1: XSS in query arguments
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
        # Match 2: XSS in JSON body
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
        # Match 3: XSS in URI path
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

  # ── ADD NEXT RULE HERE ───────────────────────────────────────────────────────
  # Copy the rule block above and update:
  #   name      → new rule name from ticket
  #   priority  → increment by 1 from last rule
  #   arn       → local.ps["NEW_PATTERN_SET_NAME"]
  #   field_to_match / text_transformation → from security team JSON
  # Then add to terraform.tfvars: "NEW_RULE_NAME" = "count"

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
