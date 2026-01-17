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

resource "aws_cloudwatch_dashboard" "sns_overview" {
  count = length(local.sns_dashboard_widgets) > 0 ? 1 : 0

  dashboard_name = "SNS-Alerting"
  dashboard_body = jsonencode({
    widgets = local.sns_dashboard_widgets
  })
}
