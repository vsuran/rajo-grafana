# Infrastructure (Terraform)

Terraform configuration to provision the Alertmanager → API Gateway → Lambda → SNS(SMS) pipeline: SNS topics + subscriptions, CloudWatch monitoring, the alert-router Lambda, and the `/alerts` API Gateway entrypoint protected by WAF.

## Prerequisites

- Terraform \>= 1.5
- AWS credentials with permissions to manage SNS (topic + subscriptions)

## Usage

1. Change into this directory:
   ```bash
   cd infra
   ```
2. (Optional) Create a `terraform.tfvars` file to override defaults and declare the SNS topics Lambda should publish to:
   ```hcl
   aws_region          = "eu-west-1"
   aws_profile         = "networking-dev"
   sns_topics = {
     sms_critical = {
       name         = "rajo-alerts-critical-sms"
       display_name = "RAJO Critical SMS"
       subscriptions = [
         {
           protocol = "sms"
           endpoint = "+15551234567"
         }
       ]
     }
     sms_warning = {
       name         = "rajo-alerts-warning-sms"
       display_name = "RAJO Warning SMS"
       subscriptions = [
         {
           protocol = "sms"
           endpoint = "+15559876543"
         }
       ]
     }
   }
   alert_router_topic_key = "sms_critical"
   cloudwatch_alarm_actions = [
     "arn:aws:sns:eu-west-1:123456789012:rajo-ops-alerts"
   ]
   tags = {
     Environment = "prod"
     Project     = "rajo-grafana"
   }
   allowed_source_ips = [
     "62.197.248.147",
     "87.197.129.110",
   ]
   ```
   Set `aws_profile` to any profile defined in your `~/.aws/credentials`/`config` files (or leave blank to use the default credential chain/environment variables).
3. Initialize and apply:
   ```bash
   terraform init
   terraform apply
   ```

The module also provisions:

- A minimal Python Lambda (`infra/lambda/alert_router/main.py`) packaged automatically and wired to the SNS topic referenced by `alert_router_topic_key`.
- An API Gateway REST API with a `POST /alerts` route that invokes the Lambda; the invoke URL is exported as `alert_router_api_endpoint`.
- An AWS WAFv2 WebACL in front of the API that only allows the `allowed_source_ips` CIDRs through.
- A CloudWatch alarm per topic watching `NumberOfNotificationsFailed` (configure alarm targets via `cloudwatch_alarm_actions`).
- A CloudWatch dashboard named `SNS-Alerting` showing publish/deliver/failure metrics for every topic.

Outputs include a map of topic keys to ARNs/names plus the API endpoint, so you can point Alertmanager’s webhook receiver at the gateway and know which SNS topic the Lambda publishes into.

## Remote State (S3)

`infra/versions.tf` configures an S3 backend so Terraform state is stored remotely. The Terraform code in this folder now provisions the required S3 bucket (`var.state_bucket_name`, default `rajo-terraform-state`) and DynamoDB table (`var.state_lock_table_name`, default `terraform-locks`) for you.

```hcl
backend "s3" {
  bucket         = "rajo-terraform-state"
  key            = "rajo-grafana/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-locks"
}
```

Because Terraform expects the backend to exist before it can store state there, bootstrap once with a local backend:

```bash
terraform init -backend=false
terraform apply -target=aws_s3_bucket.tf_state -target=aws_dynamodb_table.tf_locks
terraform init -reconfigure
```

After the bucket/table exist you can run `terraform apply` normally. If you change backend settings later, rerun `terraform init -reconfigure`.
