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
     resources = [ aws_s3_bucket.main_bucket.arn]
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

data "aws_ecr_image" "scraper_image" {
  repository_name = aws_ecr_repository.rearc_scraper.name
  image_tag       = "latest"
}

data "aws_ecr_image" "reports_image" {
  repository_name = aws_ecr_repository.rearc_reports.name
  image_tag       = "latest"
}


#resource "aws_lambda_function" "lambda_scraper" {
#  # image_uri = "${data.aws_ecr_image.scraper_image.registry_id}:latest"
#  image_uri = "${aws_ecr_repository.rearc_scraper.registry_id}:latest"
#  function_name                  = "rearc_terraform_scraper"
#  role                           = aws_iam_role.lambda.arn
#  depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
#  package_type = "Image"
#}

#resource "aws_lambda_function" "lambda_reports" {
#  # image_uri = "${data.aws_ecr_image.reports_image.registry_id}:latest"
#  image_uri = "${aws_ecr_repository.rearc_reports.registry_id}:latest"
#  function_name                  = "rearc_terraform_reports"
#  role                           = aws_iam_role.lambda.arn
#  depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
#  package_type = "Image"
#}




















#resource "aws_lambda_function" "terraform_lambda_func" {
#  filename                       = "${path.module}/create_reports_image.sh"
#  function_name                  = "rearc_terraform_scraper"
#  role                           = aws_iam_role.lambda_role.arn
#  handler                        = "index.lambda_handler"
#  runtime                        = "python3.8"
#  depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
#}