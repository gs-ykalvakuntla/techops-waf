#!/bin/bash
# associate-rule-group.sh
#
# ONE-TIME script — run once per region after Terraform creates the rule group.
# Associates gainsight-rules-global with ALL existing WAF ACLs in the region.
# After this runs, all future rules added via Terraform are live in all ACLs
# automatically — no need to run this script again.
#
# Usage:
#   ./scripts/associate-rule-group.sh <region> <rule-group-arn>
#
# Example:
#   ./scripts/associate-rule-group.sh us-east-1 \
#     arn:aws:wafv2:us-east-1:895034595272:regional/rulegroup/gainsight-rules-global/xxxx
#
# Get the rule group ARN from Terraform output:
#   cd layers/us1-rule-groups && terraform output rule_group_arn
#
# Prerequisites:
#   - AWS CLI configured with credentials for the target account
#   - jq installed (brew install jq / apt install jq)

set -e

REGION="${1:?ERROR: region required. Usage: $0 <region> <rule-group-arn>}"
RULE_GROUP_ARN="${2:?ERROR: rule-group-arn required. Usage: $0 <region> <rule-group-arn>}"
PRIORITY=100  # Priority for rule group reference — sits after existing ACL rules

echo "════════════════════════════════════════════════════════"
echo "  Associate gainsight-rules-global with all ACLs"
echo "════════════════════════════════════════════════════════"
echo "  Region:         $REGION"
echo "  Rule Group ARN: $RULE_GROUP_ARN"
echo "  Priority:       $PRIORITY"
echo "════════════════════════════════════════════════════════"
echo ""

# Verify AWS credentials work
echo "Verifying AWS credentials..."
aws sts get-caller-identity --region "$REGION" > /dev/null
echo "  OK"
echo ""

# List all WebACLs in this region
echo "Fetching all WAF ACLs in $REGION..."
ACLS=$(aws wafv2 list-web-acls \
  --scope REGIONAL \
  --region "$REGION" \
  --output json \
  --query 'WebACLs[].{Name:Name,Id:Id}')

TOTAL=$(echo "$ACLS" | jq length)
echo "  Found $TOTAL ACLs"
echo ""

SKIPPED=0
ASSOCIATED=0
FAILED=0

echo "$ACLS" | jq -c '.[]' | while read -r acl; do
  NAME=$(echo "$acl" | jq -r '.Name')
  ID=$(echo "$acl" | jq -r '.Id')

  echo "Processing: $NAME"

  # Get current ACL config + lock token
  CURRENT=$(aws wafv2 get-web-acl \
    --name "$NAME" \
    --id "$ID" \
    --scope REGIONAL \
    --region "$REGION" \
    --output json)

  LOCK_TOKEN=$(echo "$CURRENT" | jq -r '.LockToken')

  # Check if rule group already associated — skip if yes
  ALREADY=$(echo "$CURRENT" | jq --arg arn "$RULE_GROUP_ARN" \
    '[.WebACL.Rules[].Statement.RuleGroupReferenceStatement.ARN? // empty] |
     map(select(. == $arn)) | length')

  if [ "$ALREADY" -gt "0" ]; then
    echo "  ✅ Already associated — skipping"
    continue
  fi

  # Build updated rules: existing rules + new rule group reference
  UPDATED_RULES=$(echo "$CURRENT" | jq \
    --arg arn "$RULE_GROUP_ARN" \
    --argjson pri "$PRIORITY" \
    '.WebACL.Rules + [{
      "Name": "gainsight-rules-global",
      "Priority": $pri,
      "Statement": {
        "RuleGroupReferenceStatement": { "ARN": $arn }
      },
      "OverrideAction": { "None": {} },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "gainsight-rules-global"
      }
    }]')

  # Update the ACL — adds rule group reference, touches nothing else
  aws wafv2 update-web-acl \
    --name "$NAME" \
    --id "$ID" \
    --scope REGIONAL \
    --region "$REGION" \
    --lock-token "$LOCK_TOKEN" \
    --default-action "$(echo "$CURRENT" | jq '.WebACL.DefaultAction')" \
    --rules "$UPDATED_RULES" \
    --visibility-config "$(echo "$CURRENT" | jq '.WebACL.VisibilityConfig')" \
    --output json > /dev/null

  echo "  ✅ Associated"
done

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Done — gainsight-rules-global associated with all"
echo "  ACLs in $REGION. Do not run this script again."
echo "════════════════════════════════════════════════════════"
