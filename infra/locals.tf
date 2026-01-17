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

  sms_recipients_enabled = contains(keys(local.sns_topics), var.sms_recipients_topic_key) && (
    var.sms_recipients_parameter_name != "" || length(var.sms_recipients) > 0
  )
  sms_parameter_names    = try(data.aws_ssm_parameters_by_path.sms_recipients["enabled"].names, [])
  sms_parameter_values   = try(nonsensitive(data.aws_ssm_parameters_by_path.sms_recipients["enabled"].values), [])
  sms_parameter_has_value = var.sms_recipients_parameter_name != "" && contains(
    local.sms_parameter_names,
    var.sms_recipients_parameter_name
  )
  sms_recipients_raw = local.sms_parameter_has_value ? local.sms_parameter_values[index(
    local.sms_parameter_names,
    var.sms_recipients_parameter_name
  )] : ""
  sms_recipients_from_ssm = [
    for recipient in split(",", local.sms_recipients_raw) : trimspace(recipient)
    if trimspace(recipient) != ""
  ]
  sms_recipients = local.sms_recipients_enabled ? distinct(
    concat(var.sms_recipients, local.sms_recipients_from_ssm)
  ) : []
  sms_parameter_subscriptions = [
    for recipient in local.sms_recipients : {
      id        = format("%s-sms-%s", var.sms_recipients_topic_key, substr(sha1(recipient), 0, 8))
      topic_key = var.sms_recipients_topic_key
      config = {
        protocol             = "sms"
        endpoint             = recipient
        raw_message_delivery = false
      }
    }
  ]

  sns_subscriptions = concat(
    flatten([
      for topic_key, topic in local.sns_topics : [
        for sub in topic.subscriptions : {
          id        = format("%s-%s-%s", topic_key, sub.protocol, substr(sha1(sub.endpoint), 0, 8))
          topic_key = topic_key
          config    = sub
        }
      ]
    ]),
    local.sms_parameter_subscriptions
  )

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
        period  = 300
        stat    = "Sum"
        view    = "timeSeries"
        stacked = false
      }
    }
  ]
}
