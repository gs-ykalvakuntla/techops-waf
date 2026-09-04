# techops-waf

Terraform-based WAF rule management across three AWS accounts.
All changes go through pull requests. GitHub Actions runs plan on PR, apply on merge.

---

## Accounts and Regions

| Account | AWS Account ID | Region |
|---------|---------------|--------|
| US1 | 895034595272 | us-east-1 |
| US2 | 180146257873 | us-west-2 |
| EU  | 665168952601 | eu-central-1 |

---

## How It Works

Instead of manually updating 30+ WAF ACLs across 3 regions, Terraform manages
one shared rule group per region. All custom security rules live in that group.
The group is attached to every ACL once (one-time script). After that, every new
rule goes into the group via a PR and is live in all ACLs automatically.

```
gainsight-rules-global  (Terraform-managed rule group)
│
├── CUSTOM_XSS    → count mode  (pending validation)
├── CUSTOM_SQLI   → block mode  (validated, switched)
└── ... future rules
│
└── attached to ALL WAF ACLs in the region (one-time setup)
    ├── us1-prod-dsapp-waf
    ├── us1-prod-apigateway-waf
    └── ... all ACLs
```

---

## Layer Structure

```
layers/
├── 00-bootstrap-us1/    S3 state bucket + GitHub OIDC role  → account 895034595272
├── 00-bootstrap-us2/    S3 state bucket + GitHub OIDC role  → account 180146257873
├── 00-bootstrap-eu/     S3 state bucket + GitHub OIDC role  → account 665168952601
│
├── us1-regex-patterns/  RegexPatternSets in us-east-1
├── us2-regex-patterns/  RegexPatternSets in us-west-2
├── eu-regex-patterns/   RegexPatternSets in eu-central-1
│
├── us1-rule-groups/     Rule group + all WAF rules for US1
├── us2-rule-groups/     Rule group + all WAF rules for US2
└── eu-rule-groups/      Rule group + all WAF rules for EU
```

### Apply Order (dependencies)

```
00-bootstrap-us1/us2/eu
  → us1/us2/eu-regex-patterns    (needs state bucket from bootstrap)
    → us1/us2/eu-rule-groups     (reads pattern ARNs from regex-patterns state)
```

---

## Security Team Workflow

### Ticket 1 — New rule in count mode

```
PR branch: feat/waf-SEC-101-custom-xss-count

Files to edit (6 files total):
  us1-regex-patterns/terraform.tfvars  → add pattern set entry (if new)
  us2-regex-patterns/terraform.tfvars  → same
  eu-regex-patterns/terraform.tfvars   → same
  us1-rule-groups/terraform.tfvars     → add "RULE_NAME" = "count"
  us2-rule-groups/terraform.tfvars     → same
  eu-rule-groups/terraform.tfvars      → same
  us1/us2/eu-rule-groups/main.tf       → add rule {} block
```

### Ticket 2 — Switch to block mode (after validation)

```
PR branch: feat/waf-SEC-101-custom-xss-block

Files to edit (3 files total):
  us1-rule-groups/terraform.tfvars     → "CUSTOM_XSS" = "count" → "block"
  us2-rule-groups/terraform.tfvars     → same
  eu-rule-groups/terraform.tfvars      → same

Nothing else changes. Rule logic untouched.
```

---

## One-Time Setup

### Step 1 — Apply bootstrap per account

```bash
# US1
cd layers/00-bootstrap-us1
# First time: comment out S3 backend in backend.tf, use local
terraform init
terraform apply
# Note the output: github_actions_role_arn

# Migrate state to S3
# Re-enable S3 backend in backend.tf
terraform init -migrate-state

# Repeat for US2 and EU
```

### Step 2 — Add GitHub Secrets

```
Repository → Settings → Secrets → Actions

Secret Name            Value
US1_WAF_AWS_ROLE_ARN  arn:aws:iam::895034595272:role/github-actions-waf-role
US2_WAF_AWS_ROLE_ARN  arn:aws:iam::180146257873:role/github-actions-waf-role
EU_WAF_AWS_ROLE_ARN   arn:aws:iam::665168952601:role/github-actions-waf-role
```

### Step 3 — Apply regex-patterns and rule-groups layers via PRs

### Step 4 — Associate rule group with all existing ACLs (once per region)

```bash
# Get rule group ARN from Terraform output
cd layers/us1-rule-groups
terraform output rule_group_arn

# Run association script
./scripts/associate-rule-group.sh us-east-1 <rule-group-arn>
./scripts/associate-rule-group.sh us-west-2 <rule-group-arn>
./scripts/associate-rule-group.sh eu-central-1 <rule-group-arn>
```

---

## State Files

| Layer | S3 Bucket | S3 Key |
|-------|-----------|--------|
| 00-bootstrap-us1 | us1-waf-tfstate | 00-bootstrap/terraform.tfstate |
| 00-bootstrap-us2 | us2-waf-tfstate | 00-bootstrap/terraform.tfstate |
| 00-bootstrap-eu  | eu-waf-tfstate  | 00-bootstrap/terraform.tfstate |
| us1-regex-patterns | us1-waf-tfstate | us1-regex-patterns/terraform.tfstate |
| us2-regex-patterns | us2-waf-tfstate | us2-regex-patterns/terraform.tfstate |
| eu-regex-patterns  | eu-waf-tfstate  | eu-regex-patterns/terraform.tfstate |
| us1-rule-groups | us1-waf-tfstate | us1-rule-groups/terraform.tfstate |
| us2-rule-groups | us2-waf-tfstate | us2-rule-groups/terraform.tfstate |
| eu-rule-groups  | eu-waf-tfstate  | eu-rule-groups/terraform.tfstate |

---

## GitHub Actions

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| terraform-plan.yml | PR to main | Detects changed layers, runs plan, posts output to PR |
| terraform-apply.yml | Merge to main | Applies in order: regex-patterns first, then rule-groups |

Both use OIDC — no AWS access keys stored in GitHub.

---

## Contact

TechOps: `@gs-ykalvakuntla` | Repo: `gs-ykalvakuntla/techops-waf`
