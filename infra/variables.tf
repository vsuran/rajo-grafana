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

variable "allowed_source_ips" {
  description = "List of IPv4 addresses allowed to call the Alertmanager webhook API"
  type        = list(string)

}

variable "cloudwatch_alarm_actions" {
  description = "List of SNS topic ARNs or other actions invoked when CloudWatch SNS alarms fire"
  type        = list(string)
  default     = []
}
