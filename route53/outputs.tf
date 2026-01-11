output "zone_id" {
  description = "Route 53 hosted zone ID"
  value       = aws_route53_zone.primary.zone_id
}

output "name_servers" {
  description = "Name server delegation set for the hosted zone"
  value       = aws_route53_zone.primary.name_servers
}
