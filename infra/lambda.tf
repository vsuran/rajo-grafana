data "archive_file" "alert_router" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/alert_router"
  output_path = "${path.module}/lambda_alert_router.zip"
}

resource "aws_iam_role" "alert_router" {
  name = "alert-router-lambda-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = local.default_tags
}

resource "aws_iam_role_policy_attachment" "alert_router_logs" {
  role       = aws_iam_role.alert_router.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "alert_router_sns" {
  name = "alert-router-sns"
  role = aws_iam_role.alert_router.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sns:Publish"]
      Resource = aws_sns_topic.this[var.alert_router_topic_key].arn
    }]
  })
}

resource "aws_lambda_function" "alert_router" {
  function_name    = "alert-router"
  role             = aws_iam_role.alert_router.arn
  runtime          = "python3.11"
  handler          = "main.handler"
  filename         = data.archive_file.alert_router.output_path
  source_code_hash = data.archive_file.alert_router.output_base64sha256
  timeout          = 10
  memory_size      = 256

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.this[var.alert_router_topic_key].arn
    }
  }

  tags = local.default_tags
}
