variable "bucket_name" {}
variable "env" {}

resource "aws_s3_bucket" "storage" {
  bucket = "${var.bucket_name}-${var.env}"
  acl    = "private"
}
