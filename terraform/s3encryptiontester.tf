resource "random_string" "echo" {
  length = 24

  special = false

  upper = false
}
resource "aws_kms_key" "echo" {
  deletion_window_in_days = 7
}

resource "aws_iam_user" "echo" {
  name = "s3tester-echo-${random_string.echo.result}"
}

resource "aws_iam_access_key" "echo" {
  user = "${aws_iam_user.echo.name}"
}

resource "local_file" "echo_key_id" { content = "${aws_iam_access_key.echo.id}", filename = "output/echo_key_id" }
resource "local_file" "echo_key_secret" { content = "${aws_iam_access_key.echo.secret}", filename = "output/echo_key_secret" }
resource "aws_s3_bucket" "echo" { bucket = "s3tester-echo-${random_string.echo.result}" }
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
            "Resource": "${aws_s3_bucket.echo.arn}"
        }
    ]
}
POLICY
}
resource "aws_s3_bucket_object" "echo_unencrypted_testfile" {
  bucket = "${aws_s3_bucket.echo.id}"
  key    = "unencrypted_testfile"
  source = "./testfile"
  etag   = "${md5(file("./testfile"))}"
}

resource "aws_s3_bucket_object" "echo_encrypted_testfile" {
  bucket = "${aws_s3_bucket.echo.id}"
  key    = "encrypted_testfile"
  source = "./testfile"
  kms_key_id = "${aws_kms_key.echo.arn}"
}

resource "local_file" "echo_bucket_name" { content = "${aws_s3_bucket.echo.id}",  filename = "output/echo_bucket_name" }
