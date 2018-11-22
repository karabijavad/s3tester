

```bash
# create the cloud resources
cd terraform
terraform init
terraform apply -var 'access_key=your_aws_access_key' -var 'secret_key=your_aws_secret_key'

cd ../

# run the tests
cd s3tester
./s3tester
```
