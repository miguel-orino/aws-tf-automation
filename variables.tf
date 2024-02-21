variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "assessment-nginxserver"
}

variable "iam_policy_SSM" {
  description = "ARN for the SSM policy"
  type        = string
  default     = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

variable "iam_policy_s3_readonly" {
  description = "s3 read only policy for instance to retrieve startup files"
  type        = string
  default     = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}