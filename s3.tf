#create s3 bucket to store load balancer logs as well as startup files for EC2 instance
resource "aws_s3_bucket" "assessment-bucket" {
  bucket = "assessment-temp-bucket"

  tags = {
    Name        = "assessment-temp-bucket"
  }
}

#create policy document to allow load balancer to access s3 to store logs
data "aws_iam_policy_document" "allow_access_from_lb" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::127311923021:root"] #Account ID for us-east-1
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.assessment-bucket.arn}/lb-access-logs/*",
    ]
  }
}

#attach s3 bucket policy to allow lb access
resource "aws_s3_bucket_policy" "allow_access_from_lb" {
  bucket = aws_s3_bucket.assessment-bucket.id
  policy = data.aws_iam_policy_document.allow_access_from_lb.json
}

#upload EC2 startup files to S3 to be retrieved by instance later
resource "aws_s3_object" "initial_files" {
  bucket = aws_s3_bucket.assessment-bucket.id
  
  for_each = fileset("files/", "*")

  key = "files/${each.value}"
  source = "files/${each.value}"
  content_type = each.value
}