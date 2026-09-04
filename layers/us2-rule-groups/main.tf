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
  # Reference by name anywhere in this file: local.ps["PATTERN_SET_NAME"]
  # ARN is automatically correct for this region — no hardcoding needed.
  ps = data.terraform_remote_state.regex_patterns.outputs.pattern_set_arns
}

# ── Rule Group: gainsight-rules-global ───────────────────────────────────────
# Attached to ALL WAF ACLs in this region via the one-time association script.
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │  HOW TO ADD A NEW RULE (when security team raises a ticket)             │
# │                                                                         │
# │  1. If the rule uses a NEW pattern set:                                 │
# │     → Add it to terraform.tfvars in all 3 *-regex-patterns layers       │
# │                                                                         │
# │  2. Add rule action to terraform.tfvars in all 3 *-rule-groups layers:  │
# │     "NEW_RULE_NAME" = "count"   ← always start with count               │
# │                                                                         │
# │  3. Add a rule {} block below — copy any existing rule as a template.   │
# │     Update: name, priority, arn (local.ps["..."]), field_to_match       │
# │                                                                         │
# │  4. Update capacity if WCU increases (see comment on capacity field)    │
# │                                                                         │
# │  5. Open one PR — same 3 main.tf files + tfvars across US1/US2/EU       │
# └─────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │  HOW TO SWITCH COUNT → BLOCK (after security team validates)            │
# │                                                                         │
# │  Only change terraform.tfvars in all 3 *-rule-groups layers:            │
# │  "RULE_NAME" = "count"  →  "RULE_NAME" = "block"                       │
# │                                                                         │
# │  No changes to this file needed.                                        │
# └─────────────────────────────────────────────────────────────────────────┘
#
# CAPACITY: Total WCU = sum of all rules below. Update when adding rules.
# WCU ref: https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statements-list.html
resource "aws_wafv2_rule_group" "custom_security" {
  name        = "gainsight-rules-global"
  description = "All custom security rules — managed by Terraform. Do not edit in console."
  scope       = "REGIONAL"
  capacity    = 200 # recalculate when adding rules

  # ── RULE: CUSTOM_XSS ────────────────────────────────────────────────────────
  # Jira: SEC-101 | Added: 2026-08-01
  # Pattern set: XSS_CUSTOM_NEW
  # Matches XSS patterns in: query arguments, JSON body, URI path
  # Action: controlled by terraform.tfvars → rule_actions["CUSTOM_XSS"]
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
            text_transformation { priority = 0; type = "URL_DECODE_UNI" }
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
            text_transformation { priority = 0; type = "URL_DECODE_UNI" }
          }
        }
        statement {
          regex_pattern_set_reference_statement {
            arn = local.ps["XSS_CUSTOM_NEW"]
            field_to_match { uri_path {} }
            text_transformation { priority = 0; type = "URL_DECODE_UNI" }
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

  # ── RULE: <NEXT_RULE_NAME> ───────────────────────────────────────────────────
  # Uncomment and fill in when next security ticket arrives.
  # Copy this block for every new rule going forward.
  #
  # Jira: <ticket-id> | Added: <date>
  # Pattern set: <PATTERN_SET_NAME>
  #
  # rule {
  #   name     = "<RULE_NAME>"          # e.g. CUSTOM_SQLI
  #   priority = 2                      # increment from previous rule
  #
  #   dynamic "action" {
  #     for_each = [lookup(var.rule_actions, "<RULE_NAME>", "count")]
  #     content {
  #       dynamic "count" {
  #         for_each = action.value == "count" ? [1] : []
  #         content {}
  #       }
  #       dynamic "block" {
  #         for_each = action.value == "block" ? [1] : []
  #         content {
  #           custom_response { response_code = 410 }
  #         }
  #       }
  #     }
  #   }
  #
  #   statement {
  #     # Paste translated HCL from security team JSON here
  #     # Replace hardcoded ARN with: local.ps["<PATTERN_SET_NAME>"]
  #   }
  #
  #   visibility_config {
  #     sampled_requests_enabled   = true
  #     cloudwatch_metrics_enabled = true
  #     metric_name                = "<RULE_NAME>"
  #   }
  # }

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
