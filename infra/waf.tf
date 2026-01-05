locals {
  allowed_source_cidrs = [for ip in var.allowed_source_ips : "${ip}/32"]
}

resource "aws_wafv2_ip_set" "allowed_sources" {
  name               = "alert-router-allowed-ips"
  description        = "IPv4 addresses allowed to invoke the alert router API"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = local.allowed_source_cidrs

  tags = local.default_tags
}

resource "aws_wafv2_web_acl" "api_allowlist" {
  name        = "alert-router-allowlist"
  description = "Allow traffic only from specific IP addresses"
  scope       = "REGIONAL"

  default_action {
    block {}
  }

  rule {
    name     = "AllowKnownIPs"
    priority = 1
    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.allowed_sources.arn
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowKnownIPs"
    }
  }

  visibility_config {
    sampled_requests_enabled   = true
    cloudwatch_metrics_enabled = true
    metric_name                = "alert-router-web-acl"
  }

  tags = local.default_tags
}

resource "aws_wafv2_web_acl_association" "api_gateway" {
  resource_arn = aws_api_gateway_stage.alert_router.arn
  web_acl_arn  = aws_wafv2_web_acl.api_allowlist.arn
}
