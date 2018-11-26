resource "random_pet" "echo" {}

resource "aws_cloudtrail" "echo_cloudtrailer" {
  name           = "s3tester-echo-cloudtrailer-${random_pet.echo.id}"
  s3_bucket_name = "${aws_s3_bucket.echo_cloudtrailer.id}"
  include_global_service_events = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.echo.arn}/"]
    }
  }
}

resource "aws_s3_bucket" "echo_cloudtrailer" {
  bucket        = "s3tester-echo-cloudtrailer-${random_pet.echo.id}"
}

resource "aws_s3_bucket_policy" "echo_cloudtrailer" {
  bucket = "${aws_s3_bucket.echo_cloudtrailer.id}"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {"Service": "cloudtrail.amazonaws.com"},
            "Action": "s3:GetBucketAcl",
            "Resource": "${aws_s3_bucket.echo_cloudtrailer.arn}"
        },
        {
            "Effect": "Allow",
            "Principal": {"Service": "cloudtrail.amazonaws.com"},
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.echo_cloudtrailer.arn}/*",
            "Condition": {"StringEquals": {"s3:x-amz-acl": "bucket-owner-full-control"}}
        }
    ]
}
POLICY
}

resource "local_file" "echo_cloudtrailer_arn" {
  content = "${aws_s3_bucket.echo_cloudtrailer.arn}"

  filename = "output/echo_cloudtrailer_arn"
}

resource "aws_kms_key" "echo" {
  deletion_window_in_days = 7
}

resource "aws_iam_user" "echo" {
  name = "s3tester-echo-${random_pet.echo.id}"
}
resource "aws_iam_user_policy" "echo" {
  name = "s3tester-echo-${random_pet.echo.id}"

  user   = "${aws_iam_user.echo.name}"
  policy = <<POLICY
{
    "Version":"2008-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["kms:*"],
            "Resource": "${aws_kms_key.echo.arn}"
        }
    ]
}
POLICY
}
resource "aws_iam_access_key" "echo" {
  user = "${aws_iam_user.echo.name}"
}

resource "local_file" "echo_key_id" { content = "${aws_iam_access_key.echo.id}", filename = "output/echo_key_id" }
resource "local_file" "echo_key_secret" { content = "${aws_iam_access_key.echo.secret}", filename = "output/echo_key_secret" }
resource "aws_s3_bucket" "echo" { bucket = "s3tester-echo-${random_pet.echo.id}" }
resource "aws_s3_bucket_policy" "echo" {
  bucket = "${aws_s3_bucket.echo.id}"

  policy = <<POLICY
{
    "Version":"2008-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {"AWS": "${aws_iam_user.echo.arn}"},
            "Action": "s3:*",
            "Resource": "${aws_s3_bucket.echo.arn}/*"
        }
    ]
}
POLICY
}
resource "aws_s3_bucket_object" "echo_unencrypted_testfile" {
  bucket = "${aws_s3_bucket.echo.id}"
  key    = "unencrypted_testfile"
  source = "./testfile"
  cache_control = "no-cache"
  acl = "private"
  etag   = "${md5(file("./testfile"))}"
}

resource "aws_s3_bucket_object" "echo_encrypted_testfile" {
  bucket = "${aws_s3_bucket.echo.id}"
  key    = "encrypted_testfile"
  source = "./testfile"
  cache_control = "no-cache"
  acl = "private"
  kms_key_id = "${aws_kms_key.echo.arn}"
}

resource "local_file" "echo_bucket_name" { content = "${aws_s3_bucket.echo.id}",  filename = "output/echo_bucket_name" }
resource "local_file" "echo_bucket_domain" { content = "${aws_s3_bucket.echo.bucket_domain_name}",  filename = "output/echo_bucket_domain" }
resource "local_file" "echo_kms_id" { content = "${aws_kms_key.echo.id}",  filename = "output/echo_kms_id" }
resource "local_file" "echo_kms_arn" { content = "${aws_kms_key.echo.arn}",  filename = "output/echo_kms_arn" }