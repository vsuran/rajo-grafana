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

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alert_router.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.alert_router.execution_arn}/*/POST/alerts"
}
