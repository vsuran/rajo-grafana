resource "aws_api_gateway_rest_api" "alert_router" {
  name        = "alert-router"
  description = "Receives Alertmanager webhooks and forwards to Lambda"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = local.default_tags
}

resource "aws_api_gateway_resource" "alerts" {
  rest_api_id = aws_api_gateway_rest_api.alert_router.id
  parent_id   = aws_api_gateway_rest_api.alert_router.root_resource_id
  path_part   = "alerts"
}

resource "aws_api_gateway_method" "alerts_post" {
  rest_api_id   = aws_api_gateway_rest_api.alert_router.id
  resource_id   = aws_api_gateway_resource.alerts.id
  http_method   = "POST"
  authorization = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "alerts_post" {
  rest_api_id             = aws_api_gateway_rest_api.alert_router.id
  resource_id             = aws_api_gateway_resource.alerts.id
  http_method             = aws_api_gateway_method.alerts_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.alert_router.invoke_arn
}

resource "aws_api_gateway_deployment" "alert_router" {
  rest_api_id = aws_api_gateway_rest_api.alert_router.id

  triggers = {
    redeploy = sha1(jsonencode([
      aws_api_gateway_integration.alerts_post.id,
      aws_api_gateway_method.alerts_post.id,
      aws_lambda_function.alert_router.function_name,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.alerts_post
  ]
}

resource "aws_api_gateway_stage" "alert_router" {
  rest_api_id  = aws_api_gateway_rest_api.alert_router.id
  deployment_id = aws_api_gateway_deployment.alert_router.id
  stage_name   = "prod"
  tags         = local.default_tags
}

resource "aws_api_gateway_method_settings" "alerts_throttle" {
  rest_api_id = aws_api_gateway_rest_api.alert_router.id
  stage_name  = aws_api_gateway_stage.alert_router.stage_name
  method_path = "alerts/POST"

  settings {
    throttling_rate_limit  = var.api_throttle_rate_limit
    throttling_burst_limit = var.api_throttle_burst_limit
  }
}

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alert_router.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.alert_router.execution_arn}/*/POST/alerts"
}

resource "aws_api_gateway_api_key" "alert_router" {
  name    = var.api_key_name
  enabled = true
  value   = var.api_key_value != "" ? var.api_key_value : null

  tags = local.default_tags
}

resource "aws_api_gateway_usage_plan" "alert_router" {
  name = var.api_usage_plan_name

  api_stages {
    api_id = aws_api_gateway_rest_api.alert_router.id
    stage  = aws_api_gateway_stage.alert_router.stage_name
  }

  throttle_settings {
    rate_limit  = var.api_usage_plan_rate_limit
    burst_limit = var.api_usage_plan_burst_limit
  }

  quota_settings {
    limit  = var.api_usage_plan_quota_limit
    period = var.api_usage_plan_quota_period
  }

  tags = local.default_tags
}

resource "aws_api_gateway_usage_plan_key" "alert_router" {
  key_id        = aws_api_gateway_api_key.alert_router.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.alert_router.id
}

resource "aws_ssm_parameter" "api_key" {
  name        = var.api_key_ssm_parameter_name
  type        = "SecureString"
  value       = aws_api_gateway_api_key.alert_router.value
  overwrite   = true
  description = "API Gateway key for alert-router"
}
