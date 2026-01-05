output "sns_topic_arns" {
  description = "Map of topic keys to SNS topic ARNs"
  value       = { for key, topic in aws_sns_topic.this : key => topic.arn }
}

output "sns_topic_names" {
  description = "Map of topic keys to SNS topic names"
  value       = { for key, topic in aws_sns_topic.this : key => topic.name }
}

output "alert_router_api_endpoint" {
  description = "Invoke URL for the API Gateway stage fronting the alert-router Lambda"
  value       = "https://${aws_api_gateway_rest_api.alert_router.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.alert_router.stage_name}"
}
