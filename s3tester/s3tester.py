#!/usr/bin/env python

import unittest

from botocore.exceptions import ClientError
import boto3

alpha_key_id = open("../terraform/output/alpha_key_id").read()
alpha_key_secret = open("../terraform/output/alpha_key_secret").read()

bravo_key_id = open("../terraform/output/bravo_key_id").read()
bravo_key_secret = open("../terraform/output/bravo_key_secret").read()

charlie_key_id = open("../terraform/output/charlie_key_id").read()
charlie_key_secret = open("../terraform/output/charlie_key_secret").read()

delta_role_arn = open("../terraform/output/delta_role_arn").read()

alpha_bucket_name = open("../terraform/output/alpha_bucket_name").read()
bravo_bucket_name = open("../terraform/output/bravo_bucket_name").read()


class TestAlpha(unittest.TestCase):
    def setUp(self):
        self.client = boto3.resource(
            's3',
            aws_access_key_id=alpha_key_id,
            aws_secret_access_key=alpha_key_secret,
        )

    def test_cant_see_bravos_objects(self):
        bravo_bucket = self.client.Bucket(name=bravo_bucket_name)
        with self.assertRaises(ClientError):
            [_ for _ in bravo_bucket.objects.all()]

    def test_cant_assume_delta(self):
        client = boto3.client('sts', aws_access_key_id=alpha_key_id,
                              aws_secret_access_key=alpha_key_secret)
        with self.assertRaises(ClientError):
            client.assume_role(
                RoleArn=delta_role_arn,
                RoleSessionName="test",
            )


class TestBravo(unittest.TestCase):
    def setUp(self):
        self.client = boto3.resource(
            's3',
            aws_access_key_id=bravo_key_id,
            aws_secret_access_key=bravo_key_secret,
        )

    def test_cant_see_alphas_objects(self):
        alpha_bucket = self.client.Bucket(name=alpha_bucket_name)
        with self.assertRaises(ClientError):
            [_ for _ in alpha_bucket.objects.all()]

    def test_can_assume_delta_to_see_alphas_objects(self):
        sts_client = boto3.client('sts', aws_access_key_id=bravo_key_id,
                                  aws_secret_access_key=bravo_key_secret)
        role_info = sts_client.assume_role(RoleArn=delta_role_arn,
                                           RoleSessionName="test")
        assumed_alpha_s3_client = boto3.resource(
            's3',
            aws_access_key_id=role_info['Credentials']['AccessKeyId'],
            aws_secret_access_key=role_info['Credentials']['SecretAccessKey'],
            aws_session_token=role_info['Credentials']['SessionToken']
        )
        alpha_bucket = assumed_alpha_s3_client.Bucket(name=alpha_bucket_name)
        [_ for _ in alpha_bucket.objects.all()]


class TestCharlie(unittest.TestCase):
    def setUp(self):
        self.client = boto3.resource(
            's3',
            aws_access_key_id=charlie_key_id,
            aws_secret_access_key=charlie_key_secret,
        )

    def test_can_see_alphas_objects(self):
        alpha_bucket = self.client.Bucket(name=alpha_bucket_name)
        [_ for _ in alpha_bucket.objects.all()]

    def test_can_see_bravos_objects(self):
        bravo_bucket = self.client.Bucket(name=bravo_bucket_name)
        [_ for _ in bravo_bucket.objects.all()]


if __name__ == '__main__':
    unittest.main()
