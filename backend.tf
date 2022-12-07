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

resource "aws_iam_role" "lambda_role" {

name   = "Spacelift_Test_Lambda_Function_Role"

assume_role_policy = <<EOF
{
 "Version": "2012-10-17",

 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },

     "Effect": "Allow",

     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_policy" "iam_policy_for_lambda" {



 name         = "aws_iam_policy_for_terraform_aws_lambda_role"
 path         = "/"
 description  = "AWS IAM Policy for managing aws lambda role"
 policy = <<EOF

{

 "Version": "2012-10-17",

 "Statement": [

   {

     "Action": [

       "logs:CreateLogGroup",

       "logs:CreateLogStream",

       "logs:PutLogEvents"

     ],

     "Resource": "arn:aws:logs:*:*:*",

     "Effect": "Allow"

   }

 ]

}

EOF

}



resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
 role        = aws_iam_role.lambda_role.name
 policy_arn  = aws_iam_policy.iam_policy_for_lambda.arn
}

resource "aws_lambda_function" "terraform_lambda_func" {
  filename                       = "${path.module}/create_lambda_package.sh"
  function_name                  = "rearc_terraform_scraper"
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "index.lambda_handler"
  runtime                        = "python3.8"
  depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}