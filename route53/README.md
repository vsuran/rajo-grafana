# Route 53 (vladosur.cc)

Terraform configuration for hosting the `vladosur.cc` DNS zone in the central AWS account.

## Structure

- `versions.tf` – Terraform and provider constraints
- `variables.tf` – Inputs such as AWS profile, domain name, and optional record map
- `main.tf` – Creates the hosted zone and any custom records
- `outputs.tf` – Exposes the zone ID and name servers

## Usage

1. Create/modify `terraform.tfvars` (example):
   ```hcl
   aws_profile = "central"
   domain_name = "vladosur.cc"
   records = {
     "@" = {
       type    = "TXT"
       ttl     = 300
       records = ["v=spf1 include:amazonses.com -all"]
     }
     "ses._domainkey" = {
       type    = "CNAME"
       records = ["ses-domainkey-id.awsdns-00.org."]
     }
   }
   ```
2. Initialize/apply:
   ```bash
   cd route53
   terraform init
   terraform apply
   ```
3. Delegate `vladosur.cc` at your registrar (or Route 53 account) to the four name servers printed in `name_servers`.

Use the `records` map to add TXT/CNAME/A/etc. for SES, API Gateway custom domains, or subdomain delegations.
