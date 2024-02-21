#create role to be used by EC2 instance
resource "aws_iam_role" "instance_role" {
  name                = "InstanceRole"
  assume_role_policy  = data.aws_iam_policy_document.instance_assume_role_policy.json # (not shown)
  managed_policy_arns = [var.iam_policy_SSM,var.iam_policy_s3_readonly,aws_iam_policy.allow_cloudwatch_logging.arn]
}

#create policy document to allow EC2 to send logs to cloudwatch
data "aws_iam_policy_document" "allow_cloudwatch_logging" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]

    resources = [
      "*",
    ]
  }
}

#create cloudwatch policy to be attached to EC2 IAM role
resource "aws_iam_policy" "allow_cloudwatch_logging" {
  name = "AllowCloudwatchLogging"
  policy = data.aws_iam_policy_document.allow_cloudwatch_logging.json
}

# resource "aws_iam_role_policy_attachment" "attachment" {
#   role = aws_iam_role.instance_role.id
#   policy_arn = aws_iam_policy.allow_cloudwatch_logging.arn
# }

#EC2 instance requires instance profile to be used for role
resource "aws_iam_instance_profile" "instance_profile" {
  name = "InstanceProfileRole"
  role = aws_iam_role.instance_role.name
}