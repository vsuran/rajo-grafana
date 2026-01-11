variable "aws_profile" {
  description = "AWS shared config profile used for authentication"
  type        = string
  default     = "default"
}

variable "aws_region" {
  description = "Region used for AWS API calls (Route53 is global but provider needs one)"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Root domain to manage inside Route 53"
  type        = string
  default     = "vladosur.cc"
}

variable "tags" {
  description = "Tags applied to hosted zone and records"
  type        = map(string)
  default     = {}
}

variable "records" {
  description = <<EOT
Optional map of additional DNS records to create. Each entry can define type, ttl, and a list of values.
EOT
  type = map(object({
    type = string
    ttl  = optional(number, 300)
    records = optional(list(string), [])
  }))
  default = {}
}
