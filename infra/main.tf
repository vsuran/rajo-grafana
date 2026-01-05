provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

locals {
  default_tags = merge({
    Component = "alert-router"
    ManagedBy = "terraform"
  }, var.tags)

  sns_topics = {
    for topic_key, topic in var.sns_topics :
    topic_key => {
      name              = try(topic.name, topic_key)
      display_name      = try(topic.display_name, null)
      kms_master_key_id = try(topic.kms_master_key_id, var.kms_master_key_id != "" ? var.kms_master_key_id : null)
      tags              = merge(local.default_tags, try(topic.tags, {}))
      subscriptions     = try(topic.subscriptions, [])
    }
  }

  sns_subscriptions = flatten([
    for topic_key, topic in local.sns_topics : [
      for sub in topic.subscriptions : {
        id        = format("%s-%s-%s", topic_key, sub.protocol, substr(sha1(sub.endpoint), 0, 8))
        topic_key = topic_key
        config    = sub
      }
    ]
  ])
}

resource "aws_sns_topic" "this" {
  for_each = local.sns_topics

  name              = each.value.name
  display_name      = each.value.display_name
  kms_master_key_id = each.value.kms_master_key_id
  tags              = each.value.tags
}

resource "aws_sns_topic_subscription" "this" {
  for_each = { for sub in local.sns_subscriptions : sub.id => sub }

  topic_arn = aws_sns_topic.this[each.value.topic_key].arn
  protocol  = each.value.config.protocol
  endpoint  = each.value.config.endpoint

  raw_message_delivery = try(each.value.config.raw_message_delivery, null)
}

resource "aws_cloudwatch_metric_alarm" "sns_notifications_failed" {
  for_each = aws_sns_topic.this

  alarm_name          = "${each.value.name}-notifications-failed"
  alarm_description   = "Alerts when SNS reports delivery failures for topic ${each.value.name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfNotificationsFailed"
  namespace           = "AWS/SNS"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  dimensions = {
    TopicName = each.value.name
  }

  alarm_actions = var.cloudwatch_alarm_actions
  ok_actions    = var.cloudwatch_alarm_actions
}

resource "aws_s3_bucket" "tf_state" {
  bucket = var.state_bucket_name

  tags = merge(local.default_tags, {
    Purpose = "terraform-state"
  })
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tf_locks" {
  name         = var.state_lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(local.default_tags, {
    Purpose = "terraform-locks"
  })
}

locals {
  sns_dashboard_widgets = [
    for idx, key in tolist(sort(keys(aws_sns_topic.this))) : {
      type   = "metric"
      width  = 24
      height = 6
      x      = 0
      y      = idx * 6
      properties = {
        region = var.aws_region
        title  = "SNS Topic: ${aws_sns_topic.this[key].name}"
        metrics = [
          ["AWS/SNS", "NumberOfMessagesPublished", "TopicName", aws_sns_topic.this[key].name],
          [".", "NumberOfNotificationsDelivered", ".", "."],
          [".", "NumberOfNotificationsFailed", ".", ".", { "yAxis" = "right" }]
        ]
        period = 300
        stat   = "Sum"
        view   = "timeSeries"
        stacked = false
      }
    }
  ]
}

resource "aws_cloudwatch_dashboard" "sns_overview" {
  count = length(local.sns_dashboard_widgets) > 0 ? 1 : 0

  dashboard_name = "SNS-Alerting"
  dashboard_body = jsonencode({
    widgets = local.sns_dashboard_widgets
  })
}
