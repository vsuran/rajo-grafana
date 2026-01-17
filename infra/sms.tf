resource "aws_sns_sms_preferences" "this" {
  default_sms_type = var.sms_default_type
}
