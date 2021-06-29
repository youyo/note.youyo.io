---
title: Terraformの簡単な書き方
date: 2021-06-29T12:26:00+09:00
tags: [AWS,Terraform,WAF]
summary: 一度手動で作成してからimportが結局楽
pin: false
draft: false
---

Terraformを使って管理したいけど0からコードを書くのはめんどくさいときがある。そういうときは一旦マネジメントコンソールから作成してしまってから`terraform import`をすると便利。

## AWS WAFのACLの設定をするケース

#### 1. マネジメントコンソールから作成する

#### 2. 最低限のコードを書く

必須パラメーターは埋める必要がある。

```
provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      Created = "Terraform"
    }
  }
}

resource "aws_wafv2_web_acl" "main" {
  name  = "acl-name"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WebACLMetrics"
    sampled_requests_enabled   = false
  }
}
```

#### 3. Init

```
$ terraform init
```

#### 4. Import

```
$ terraform import aws_wafv2_web_acl.main ffbdf401-5604-4f93-8373-xxxxxxxxxxx/acl-name/REGIONAL
```

#### 5. Planを実行して差分を取得

```
$ terraform plan
.
.
.

  # aws_wafv2_web_acl.main will be updated in-place
  ~ resource "aws_wafv2_web_acl" "main" {
      - description = "acl-name" -> null
        id          = "ffbdf401-5604-4f93-8373-xxxxxxxxxxx"
        name        = "acl-name"
        # (4 unchanged attributes hidden)


      - rule {
          - name     = "allow-kibana" -> null
          - priority = 0 -> null

          - action {
              - allow {
                }
            }

          - statement {

              - byte_match_statement {
                  - positional_constraint = "STARTS_WITH" -> null
                  - search_string         = "/_plugin/kibana" -> null

                  - field_to_match {

                      - uri_path {}
                    }

                  - text_transformation {
                      - priority = 0 -> null
                      - type     = "NONE" -> null
                    }
                }
            }

          - visibility_config {
              - cloudwatch_metrics_enabled = true -> null
              - metric_name                = "allow-kibana" -> null
              - sampled_requests_enabled   = false -> null
            }
        }
      - rule {
          - name     = "AWSManagedRulesCommonRuleSet" -> null
          - priority = 1 -> null

          - override_action {

              - none {}
            }

          - statement {

              - managed_rule_group_statement {
                  - name        = "AWSManagedRulesCommonRuleSet" -> null
                  - vendor_name = "AWS" -> null

                  - excluded_rule {
                      - name = "SizeRestrictions_BODY" -> null
                    }
                }
            }

          - visibility_config {
              - cloudwatch_metrics_enabled = true -> null
              - metric_name                = "AWSManagedRulesCommonRuleSetMetric" -> null
              - sampled_requests_enabled   = false -> null
            }
        }
      - rule {
          - name     = "AWSManagedRulesKnownBadInputsRuleSet" -> null
          - priority = 2 -> null

          - override_action {

              - none {}
            }

          - statement {

              - managed_rule_group_statement {
                  - name        = "AWSManagedRulesKnownBadInputsRuleSet" -> null
                  - vendor_name = "AWS" -> null
                }
            }

          - visibility_config {
              - cloudwatch_metrics_enabled = true -> null
              - metric_name                = "AWSManagedRulesKnownBadInputsRuleSetMetric" -> null
              - sampled_requests_enabled   = false -> null
            }
        }
      - rule {
          - name     = "AWSManagedRulesLinuxRuleSet" -> null
          - priority = 3 -> null

          - override_action {

              - none {}
            }

          - statement {

              - managed_rule_group_statement {
                  - name        = "AWSManagedRulesLinuxRuleSet" -> null
                  - vendor_name = "AWS" -> null
                }
            }

          - visibility_config {
              - cloudwatch_metrics_enabled = true -> null
              - metric_name                = "AWSManagedRulesLinuxRuleSetMetric" -> null
              - sampled_requests_enabled   = false -> null
            }
        }
      - rule {
          - name     = "AWSManagedRulesPHPRuleSet" -> null
          - priority = 4 -> null

          - override_action {

              - none {}
            }

          - statement {

              - managed_rule_group_statement {
                  - name        = "AWSManagedRulesPHPRuleSet" -> null
                  - vendor_name = "AWS" -> null
                }
            }

          - visibility_config {
              - cloudwatch_metrics_enabled = true -> null
              - metric_name                = "AWSManagedRulesPHPRuleSetMetric" -> null
              - sampled_requests_enabled   = false -> null
            }
        }
      - rule {
          - name     = "AWSManagedRulesSQLiRuleSet" -> null
          - priority = 5 -> null

          - override_action {

              - none {}
            }

          - statement {

              - managed_rule_group_statement {
                  - name        = "AWSManagedRulesSQLiRuleSet" -> null
                  - vendor_name = "AWS" -> null
                }
            }

          - visibility_config {
              - cloudwatch_metrics_enabled = true -> null
              - metric_name                = "AWSManagedRulesSQLiRuleSetMetric" -> null
              - sampled_requests_enabled   = false -> null
            }
        }

        # (2 unchanged blocks hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

#### 6. planの結果とコードをマージする

余計な`- ` `~ ` ` -> null` `# (2 unchanged blocks hidden)` みたいなものを削除すればok.

```
provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      Created = "Terraform"
    }
  }
}

resource "aws_wafv2_web_acl" "main" {
  name        = "acl-name"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WebACLMetrics"
    sampled_requests_enabled   = false
  }

  rule {
    name     = "allow-kibana"
    priority = 0

    action {
      allow {}
    }

    statement {
      byte_match_statement {
        positional_constraint = "STARTS_WITH"
        search_string         = "/_plugin/kibana"

        field_to_match {
          uri_path {}
        }

        text_transformation {
          priority = 0
          type     = "NONE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "allow-kibana"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        excluded_rule {
          name = "SizeRestrictions_BODY"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSetMetric"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "AWSManagedRulesLinuxRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesLinuxRuleSetMetric"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "AWSManagedRulesPHPRuleSet"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesPHPRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesPHPRuleSetMetric"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 5

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSetMetric"
      sampled_requests_enabled   = false
    }
  }
}
```

#### 7. planで確認して差分がなくなればok

```
$ terraform plan
aws_wafv2_web_acl.main: Refreshing state... [id=ffbdf401-5604-4f93-8373-xxxxxxxxxxx]
```

## 注意点

- `terraform import`に対応していないresourceであった場合は使えない
