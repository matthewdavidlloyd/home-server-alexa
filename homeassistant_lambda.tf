data "aws_iam_policy_document" "homeassistant_lambda" {
    statement {
        effect = "Allow"

        principals {
            type        = "Service"
            identifiers = ["lambda.amazonaws.com"]
        }

        actions = ["sts:AssumeRole"]
    }
}

resource "aws_iam_role" "homeassistant_lambda" {
    name                = "homeassistant_lambda"
    assume_role_policy  = data.aws_iam_policy_document.homeassistant_lambda.json
}

data "archive_file" "homeassistant_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/homeassistant/main.py"
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "homeassistant_lambda" {
    filename      = data.archive_file.homeassistant_lambda.output_path
    function_name = "homeassistant"
    role          = aws_iam_role.homeassistant_lambda.arn
    handler       = "main.handler"

    source_code_hash = data.archive_file.homeassistant_lambda.output_base64sha256

    runtime = "python3.11"

    environment {
      variables = {
        BASE_URL = var.homeassistant_base_url
      }
    }
}

resource "aws_lambda_permission" "homeassistant_lambda" {
    statement_id        = "AllowExecutionFromAlexa"
    action              = "lambda:InvokeFunction"
    function_name       = aws_lambda_function.homeassistant_lambda.function_name
    principal           = "alexa-connectedhome.amazon.com"
    event_source_token  = var.homeassistant_skill_id
}
