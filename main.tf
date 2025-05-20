provider "aws" {
  region = var.region
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-scale-ecs-asg-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect = "Allow",
        Sid = ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_inline_policy" {
  name = "scale-permission"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "autoscaling:UpdateAutoScalingGroup",
          "ecs:UpdateService"
        ],
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/lambda/handler.zip"
}

resource "aws_lambda_function" "scale_lambda" {
  function_name = "scale-ecs-asg"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.9"
  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      ASG_NAME              = var.asg_name
      ECS_CLUSTER           = var.ecs_cluster
      ECS_SERVICE           = var.ecs_service
      SCALE_UP_MIN_SIZE     = tostring(var.scale_up_min_size)
      SCALE_UP_DESIRED      = tostring(var.scale_up_desired_capacity)
      SCALE_UP_MAX_SIZE     = tostring(var.scale_up_max_size)
      SCALE_UP_ECS_COUNT    = tostring(var.scale_up_ecs_count)
    }
  }
}

resource "aws_cloudwatch_event_rule" "scale_down" {
  name                = "scale-down"
  schedule_expression = var.scale_down_cron
}

resource "aws_cloudwatch_event_target" "scale_down_target" {
  rule      = aws_cloudwatch_event_rule.scale_down.name
  target_id = "scaleDownTarget"
  arn       = aws_lambda_function.scale_lambda.arn
  input     = jsonencode({ action = "scale_down" })
}

resource "aws_cloudwatch_event_rule" "scale_up" {
  name                = "scale-up"
  schedule_expression = var.scale_up_cron
}

resource "aws_cloudwatch_event_target" "scale_up_target" {
  rule      = aws_cloudwatch_event_rule.scale_up.name
  target_id = "scaleUpTarget"
  arn       = aws_lambda_function.scale_lambda.arn
  input     = jsonencode({ action = "scale_up" })
}

resource "aws_lambda_permission" "allow_eventbridge_scale_down" {
  statement_id  = "AllowExecutionFromEventBridgeDown"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scale_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scale_down.arn
}

resource "aws_lambda_permission" "allow_eventbridge_scale_up" {
  statement_id  = "AllowExecutionFromEventBridgeUp"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scale_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scale_up.arn
}