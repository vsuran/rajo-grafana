variable "aws_region" {
  description = "AWS region where the SNS topic will be created"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Shared AWS profile name used for credentials (leave empty to use env vars/default chain)"
  type        = string
  default     = "default"
}

variable "kms_master_key_id" {
  description = "Optional KMS key ARN/ID to encrypt the SNS topic"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to every Terraform-managed resource"
  type        = map(string)
  default     = {}
}

variable "state_bucket_name" {
  description = "Name for the S3 bucket storing Terraform state"
  type        = string
  default     = "rajo-terraform-state"
}

variable "state_lock_table_name" {
  description = "Name for the DynamoDB table used as Terraform state lock"
  type        = string
  default     = "terraform-locks"
}

variable "sns_topics" {
  description = <<EOT
Map describing the SNS topics the alert-router Lambda can publish to. Each topic can define its own display name,
optional tags, and a list of downstream subscriptions (SMS, email, HTTPS endpoints, etc.).
EOT
  type = map(object({
    name          = optional(string)
    display_name  = optional(string)
    kms_master_key_id = optional(string)
    tags          = optional(map(string))
    subscriptions = optional(list(object({
      protocol             = string
      endpoint             = string
      raw_message_delivery = optional(bool, false)
    })), [])
  }))

  default = {
    sms = {
      name         = "rajo-alerts-sms"
      display_name = "RAJO SMS Alerts"
      subscriptions = []
    }
  }
}

variable "alert_router_topic_key" {
  description = "Key in sns_topics map whose ARN will be injected into the alert-router Lambda"
  type        = string
  default     = "sms"
}

variable "sms_recipients_parameter_name" {
  description = "Optional SSM parameter name containing comma-separated SMS recipients (StringList)"
  type        = string
  default     = ""
}

variable "sms_recipients_topic_key" {
  description = "sns_topics key that should receive SMS recipients from Parameter Store"
  type        = string
  default     = "sms"
}

variable "allowed_source_ips" {
  description = "List of IPv4 addresses allowed to call the Alertmanager webhook API"
  type        = list(string)

}

variable "cloudwatch_alarm_actions" {
  description = "List of SNS topic ARNs or other actions invoked when CloudWatch SNS alarms fire"
  type        = list(string)
  default     = []
}

variable "sms_default_type" {
  description = "Default SMS type for AWS SNS (Transactional or Promotional)"
  type        = string
  default     = "Transactional"
}

variable "sms_recipients" {
  description = "List of SMS recipient phone numbers to store in SSM"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for recipient in var.sms_recipients : can(regex("^\\+[1-9][0-9]{1,14}$", recipient))
    ])
    error_message = "Each sms_recipients entry must be in E.164 format, e.g. +421903322606."
  }
}

variable "sms_recipients_overwrite" {
  description = "Whether to overwrite the SMS recipients SSM parameter if it already exists"
  type        = bool
  default     = true
}

variable "api_throttle_rate_limit" {
  description = "Steady-state requests per second allowed by API Gateway"
  type        = number
  default     = 1
}

variable "api_throttle_burst_limit" {
  description = "Burst requests allowed by API Gateway"
  type        = number
  default     = 2
}

variable "api_key_name" {
  description = "Name for the API Gateway API key"
  type        = string
  default     = "alert-router-key"
}

variable "api_key_value" {
  description = "Optional static API key value (leave empty to auto-generate)"
  type        = string
  default     = ""
}

variable "api_usage_plan_name" {
  description = "Name for the API Gateway usage plan"
  type        = string
  default     = "alert-router-plan"
}

variable "api_usage_plan_rate_limit" {
  description = "Steady-state requests per second allowed by usage plan"
  type        = number
  default     = 0.0111111111
}

variable "api_usage_plan_burst_limit" {
  description = "Burst requests allowed by usage plan"
  type        = number
  default     = 1
}

variable "api_usage_plan_quota_limit" {
  description = "Maximum requests allowed in the quota period"
  type        = number
  default     = 100
}

variable "api_usage_plan_quota_period" {
  description = "Quota period for API usage (DAY, WEEK, or MONTH)"
  type        = string
  default     = "DAY"
}

variable "api_key_ssm_parameter_name" {
  description = "SSM parameter name to store the API key value"
  type        = string
  default     = "/alerts/api/key"
}
