resource "aws_ssm_parameter" "sms_recipients" {
  count = var.sms_recipients_parameter_name != "" && length(var.sms_recipients) > 0 ? 1 : 0

  name        = var.sms_recipients_parameter_name
  type        = "StringList"
  value       = join(",", var.sms_recipients)
  overwrite   = var.sms_recipients_overwrite
  description = "SMS recipients for alerting"
}
