aws_region  = "eu-west-1"
aws_profile = "acsnet"
state_bucket_name     = "rajo-terraform-state"
state_lock_table_name = "terraform-locks"

cloudwatch_alarm_actions = [
  "arn:aws:sns:eu-west-1:385085470418:rajo-alerts-sms-primary"
]

alert_router_topic_key = "sms_primary"

allowed_source_ips = [
  "62.197.248.147",
  "87.197.129.110",
]

tags = {
  Environment = "dev"
  Project     = "rajo-grafana"
}

sns_topics = {
  sms_primary = {
    name         = "rajo-alerts-sms-primary"
    display_name = "RAJO Primary SMS"
    subscriptions = [
      {
        protocol = "sms"
        endpoint = "+421903322606"
      }
    ]
  }

  sms_backup = {
    name         = "rajo-alerts-sms-backup"
    display_name = "RAJO Backup SMS"
    subscriptions = [
      {
        protocol = "sms"
        endpoint = "+421903322606"
      }
    ]
  }
}

