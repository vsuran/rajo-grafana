provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

locals {
  default_tags = merge({
    Component = "dns"
    ManagedBy = "terraform"
  }, var.tags)
}

resource "aws_route53_zone" "primary" {
  name = var.domain_name
  tags = local.default_tags
}

resource "aws_route53_record" "custom" {
  for_each = var.records

  zone_id = aws_route53_zone.primary.zone_id
  name    = each.key == "@" ? var.domain_name : "${each.key}.${var.domain_name}"
  type    = upper(each.value.type)
  ttl     = coalesce(each.value.ttl, 300)
  records = each.value.records
}
