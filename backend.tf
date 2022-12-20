provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_s3_bucket" "main_bucket" {
  bucket = "ryanfore-rearc"
}

resource "aws_s3_bucket_acl" "main_bucket" {
  bucket = aws_s3_bucket.main_bucket.id
  acl = "public-read"
}

resource aws_iam_role lambda {
 name = "lambda-role"
 assume_role_policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
       {
           "Action": "sts:AssumeRole",
           "Principal": {
               "Service": "lambda.amazonaws.com"
           },
           "Effect": "Allow"
       }
   ]
}
 EOF
}

data aws_iam_policy_document lambda {
   statement {
     actions = [
         "logs:CreateLogGroup",
         "logs:CreateLogStream",
         "logs:PutLogEvents"
     ]
     effect = "Allow"
     resources = [ "*" ]
     sid = "CreateCloudWatchLogs"
   }

   statement {
     actions = [
       "s3:GetBucketLocation",
       "s3:PutObject",
       "s3:DeleteObject",
       "s3:ListBucket",
       "s3:GetObject"
     ]
     effect = "Allow"
     resources = ["${aws_s3_bucket.main_bucket.arn}*"]
   }
}

resource aws_iam_policy lambda {
   name = "lambda-policy"
   path = "/"
   policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
 role        = aws_iam_role.lambda.name
 policy_arn  = aws_iam_policy.lambda.arn
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_role_policy" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

data "aws_ecr_authorization_token" "token" {
}

resource "aws_ecr_repository" "rearc_scraper" {
  name   = "rearc_scraper"
}

resource "aws_ecr_repository" "rearc_reports" {
  name   = "rearc_reports"
}

resource "null_resource" "base_images" {
  # 1 Time execution that pushes base images so that the lambda function can be created
 provisioner "local-exec" {

   command = <<EOF
      docker login ${data.aws_ecr_authorization_token.token.proxy_endpoint} -u AWS -p ${data.aws_ecr_authorization_token.token.password}
      docker pull alpine
      docker tag alpine ${aws_ecr_repository.rearc_scraper.repository_url}:latest
      docker push ${aws_ecr_repository.rearc_scraper.repository_url}:latest
      docker tag alpine ${aws_ecr_repository.rearc_reports.repository_url}:latest
      docker push ${aws_ecr_repository.rearc_reports.repository_url}:latest
      EOF
  }
}

resource "aws_lambda_function" "lambda_scraper" {
  image_uri = "${aws_ecr_repository.rearc_scraper.repository_url}:latest"
  function_name                  = "rearc_terraform_scraper"
  role                           = aws_iam_role.lambda.arn
  depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
  package_type = "Image"
  timeout = 60
}

resource "aws_lambda_function" "lambda_reports" {
  image_uri = "${aws_ecr_repository.rearc_reports.repository_url}:latest"
  function_name                  = "rearc_terraform_reports"
  role                           = aws_iam_role.lambda.arn
  depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
  package_type = "Image"

}


resource "aws_cloudwatch_event_rule" "daily_cron_lambda_event_rule" {
  name = "daily_cron_lambda_event_rule"
  description = "Run Daily"
  schedule_expression = "cron(0 0 ? * * *)"
}

resource "aws_cloudwatch_event_target" "profile_generator_lambda_target" {
  arn =aws_lambda_function.lambda_scraper.arn
  rule = aws_cloudwatch_event_rule.daily_cron_lambda_event_rule.name
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_scraper" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  principal = "events.amazonaws.com"
  function_name = aws_lambda_function.lambda_scraper.function_name
  source_arn = aws_cloudwatch_event_rule.daily_cron_lambda_event_rule.arn
}


resource "aws_sqs_queue" "q" {
  name = "s3-event-queue"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:*:*:s3-event-queue",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.main_bucket.arn}" }
      }
    }
  ]
}
POLICY
}


resource "aws_s3_bucket_notification" "reports_trigger" {
  bucket = aws_s3_bucket.main_bucket.bucket

  queue {
    queue_arn     = aws_sqs_queue.q.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix       = ".json"
  }
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  event_source_arn = aws_sqs_queue.q.arn
  function_name    = aws_lambda_function.lambda_reports.arn
}
