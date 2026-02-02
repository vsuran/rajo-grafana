aws_region  = "eu-west-1"
aws_profile = "networking-dev"

sns_topics = {
  sms_critical = {
    name         = "rajo-alerts-critical-sms"
    display_name = "RAJO Critical SMS"
    subscriptions = []
  }
}

alert_router_topic_key = "sms_critical"

sms_recipients_parameter_name = "/alerts/sms/recipients"
sms_recipients_topic_key      = "sms_critical"

cloudwatch_alarm_actions = [
  "arn:aws:sns:eu-west-1:123456789012:rajo-ops-alerts"
]

sms_default_type = "Transactional"

sms_recipients = [
  "+421903322606",
  "+421902106186",
  "+421905457678"
]

api_throttle_rate_limit  = 0.0111111111
api_throttle_burst_limit = 1

api_key_name       = "alert-router-key"
api_usage_plan_name = "alert-router-plan"
api_usage_plan_rate_limit  = 0.0111111111
api_usage_plan_burst_limit = 1
api_usage_plan_quota_limit = 100
api_usage_plan_quota_period = "DAY"
api_key_ssm_parameter_name = "/alerts/api/key"

tags = {
  Environment = "prod"
  Project     = "rajo-grafana"
}

allowed_source_ips = [
  "62.197.248.147",
  "87.197.129.110",
]
