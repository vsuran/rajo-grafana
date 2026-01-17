data "aws_ssm_parameters_by_path" "sms_recipients" {
  for_each = var.sms_recipients_parameter_name != "" ? { enabled = true } : {}

  path            = dirname(var.sms_recipients_parameter_name)
  recursive       = false
  with_decryption = false
}
