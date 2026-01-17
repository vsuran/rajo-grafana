resource "aws_sns_topic" "this" {
  for_each = local.sns_topics

  name              = each.value.name
  display_name      = each.value.display_name
  kms_master_key_id = each.value.kms_master_key_id
  tags              = each.value.tags
}

resource "aws_sns_topic_subscription" "this" {
  for_each = { for sub in nonsensitive(local.sns_subscriptions) : sub.id => sub }

  topic_arn = aws_sns_topic.this[each.value.topic_key].arn
  protocol  = each.value.config.protocol
  endpoint  = each.value.config.endpoint

  raw_message_delivery = try(each.value.config.raw_message_delivery, null)
}
