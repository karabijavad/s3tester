#!/usr/bin/env python

import unittest

from botocore.client import Config
from botocore.exceptions import ClientError
import boto3
import requests

region = open("../terraform/output/region").read()

alpha_key_id = open("../terraform/output/alpha_key_id").read()
alpha_key_secret = open("../terraform/output/alpha_key_secret").read()

bravo_key_id = open("../terraform/output/bravo_key_id").read()
bravo_key_secret = open("../terraform/output/bravo_key_secret").read()

charlie_key_id = open("../terraform/output/charlie_key_id").read()
charlie_key_secret = open("../terraform/output/charlie_key_secret").read()

echo_key_id = open("../terraform/output/echo_key_id").read()
echo_key_secret = open("../terraform/output/echo_key_secret").read()

delta_role_arn = open("../terraform/output/delta_role_arn").read()

alpha_bucket_name = open("../terraform/output/alpha_bucket_name").read()
bravo_bucket_name = open("../terraform/output/bravo_bucket_name").read()
echo_bucket_name = open("../terraform/output/echo_bucket_name").read()
echo_bucket_domain = open("../terraform/output/echo_bucket_domain").read()
echo_kms_id = open("../terraform/output/echo_kms_id").read()


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
        client = boto3.client(
            'sts',
            aws_access_key_id=alpha_key_id,
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
        sts_client = boto3.client(
            'sts',
            aws_access_key_id=bravo_key_id,
            aws_secret_access_key=bravo_key_secret)
        role_info = sts_client.assume_role(
            RoleArn=delta_role_arn, RoleSessionName="test")
        assumed_alpha_s3_client = boto3.resource(
            's3',
            aws_access_key_id=role_info['Credentials']['AccessKeyId'],
            aws_secret_access_key=role_info['Credentials']['SecretAccessKey'],
            aws_session_token=role_info['Credentials']['SessionToken'])
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

    def test_cant_assume_delta(self):
        client = boto3.client(
            'sts',
            aws_access_key_id=alpha_key_id,
            aws_secret_access_key=alpha_key_secret)
        with self.assertRaises(ClientError):
            client.assume_role(
                RoleArn=delta_role_arn,
                RoleSessionName="test",
            )


class TestEncryption(unittest.TestCase):
    def setUp(self):
        print(echo_key_id)
        print(echo_key_secret)

        session = boto3.Session(
            aws_access_key_id=echo_key_id,
            aws_secret_access_key=echo_key_secret,
            region_name=region)

        s3 = session.client(
            's3',
            config=Config(
                signature_version='s3v4', s3={'addressing_style': 'path'}),
            region_name=region)

        self.unencrypted_testfile_url = s3.generate_presigned_url(
            ClientMethod='get_object',
            Params={
                'Bucket': echo_bucket_name,
                'Key': 'unencrypted_testfile'
            })

        self.encrypted_testfile_url = s3.generate_presigned_url(
            ClientMethod='get_object',
            Params={
                'Bucket': echo_bucket_name,
                'Key': 'encrypted_testfile'
            })

    def test_download_files(self):
        print(self.unencrypted_testfile_url)
        print(self.encrypted_testfile_url)
        print(echo_kms_id)
        unencrypted_testfile_response = requests.get(
            self.unencrypted_testfile_url)
        encrypted_testfile_response = requests.get(self.encrypted_testfile_url)

        self.assertEqual(unencrypted_testfile_response.status_code, 200)
        self.assertEqual(encrypted_testfile_response.status_code, 200)


if __name__ == '__main__':
    unittest.main()
