provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "random_pet" "alpha" {}

resource "random_pet" "bravo" {}

resource "random_pet" "charlie" {}

resource "random_pet" "delta" {}

# users / roles
resource "aws_iam_user" "alpha" {
  name = "s3tester-alpha-${random_pet.alpha.id}"
}

resource "aws_iam_user" "bravo" {
  name = "s3tester-bravo-${random_pet.bravo.id}"
}

resource "aws_iam_user" "charlie" {
  name = "s3tester-charlie-${random_pet.charlie.id}"
}

resource "aws_iam_role" "delta" {
  name = "s3tester-delta-${random_pet.delta.id}"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [{
      "Action": "sts:AssumeRole", "Effect": "Allow",
      "Principal": { "AWS": "${aws_iam_user.bravo.arn}" }
  }]
}
EOF
}

# keys
resource "aws_iam_access_key" "alpha" {
  user = "${aws_iam_user.alpha.name}"
}

resource "aws_iam_access_key" "bravo" {
  user = "${aws_iam_user.bravo.name}"
}

resource "aws_iam_access_key" "charlie" {
  user = "${aws_iam_user.charlie.name}"
}

# user policies
resource "aws_iam_user_policy" "alpha" {
  name = "s3tester-alpha-${random_pet.alpha.id}"

  user   = "${aws_iam_user.alpha.name}"
  policy = "{\"Statement\": [{\"Action\": \"s3:*\", \"Effect\": \"Allow\", \"Resource\": \"*\" }] }"
}

resource "aws_iam_user_policy" "bravo" {
  name = "s3tester-bravo-${random_pet.bravo.id}"

  user   = "${aws_iam_user.bravo.name}"
  policy = "{\"Statement\": [{\"Action\": \"s3:*\", \"Effect\": \"Allow\", \"Resource\": \"*\" }] }"
}

resource "aws_iam_user_policy" "charlie" {
  name = "s3tester-charlie-${random_pet.charlie.id}"

  user   = "${aws_iam_user.charlie.name}"
  policy = "{\"Statement\": [{\"Action\": \"s3:*\", \"Effect\": \"Allow\", \"Resource\": \"*\" }] }"
}

# buckets
resource "aws_s3_bucket" "alpha" {
  bucket = "s3tester-alpha-${random_pet.alpha.id}"
}

resource "aws_s3_bucket_policy" "alpha" {
  bucket = "${aws_s3_bucket.alpha.id}"

  policy = <<POLICY
{
    "Version":"2008-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:ListBucket",
            "Resource": "${aws_s3_bucket.alpha.arn}",
            "Condition": {
                "ForAnyValue:StringNotEquals": {
                    "aws:username": [
                        "${aws_iam_user.alpha.name}",
                        "${aws_iam_user.charlie.name}",
                        "javad",
                        "karabijavad@gmail.com"
                    ]
                }
            }
        },
        {
            "Effect": "Allow",
            "Principal": { "AWS": "${aws_iam_role.delta.arn}" },
            "Action": "s3:ListBucket",
            "Resource": "${aws_s3_bucket.alpha.arn}"
        }
    ]
}
POLICY
}

resource "aws_s3_bucket" "bravo" {
  bucket = "s3tester-bravo-${random_pet.bravo.id}"
}

resource "aws_s3_bucket_policy" "bravo" {
  bucket = "${aws_s3_bucket.bravo.id}"

  policy = <<POLICY
{
    "Version":"2008-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:ListBucket",
            "Resource": "${aws_s3_bucket.bravo.arn}",
            "Condition": {
                "ForAnyValue:StringNotEquals": {
                    "aws:username": [
                        "${aws_iam_user.bravo.name}",
                        "${aws_iam_user.charlie.name}",
                        "javad",
                        "karabijavad@gmail.com"
                    ]
                }
            }
        }
    ]
}
POLICY
}

# output files
resource "local_file" "alpha_key_id" {
  content = "${aws_iam_access_key.alpha.id}"

  filename = "output/alpha_key_id"
}

resource "local_file" "alpha_key_secret" {
  content = "${aws_iam_access_key.alpha.secret}"

  filename = "output/alpha_key_secret"
}

resource "local_file" "alpha_bucket_name" {
  content = "${aws_s3_bucket.alpha.id}"

  filename = "output/alpha_bucket_name"
}

resource "local_file" "bravo_key_id" {
  content = "${aws_iam_access_key.bravo.id}"

  filename = "output/bravo_key_id"
}

resource "local_file" "bravo_key_secret" {
  content = "${aws_iam_access_key.bravo.secret}"

  filename = "output/bravo_key_secret"
}

resource "local_file" "bravo_bucket_name" {
  content = "${aws_s3_bucket.bravo.id}"

  filename = "output/bravo_bucket_name"
}

resource "local_file" "charlie_key_id" {
  content = "${aws_iam_access_key.charlie.id}"

  filename = "output/charlie_key_id"
}

resource "local_file" "charlie_key_secret" {
  content = "${aws_iam_access_key.charlie.secret}"

  filename = "output/charlie_key_secret"
}

resource "local_file" "delta_role_arn" {
  content = "${aws_iam_role.delta.arn}"

  filename = "output/delta_role_arn"
}

resource "local_file" "region" {
  content = "${var.region}"

  filename = "output/region"
}
