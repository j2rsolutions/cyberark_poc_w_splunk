
resource "aws_route53_record" "app_fqdn" {
  zone_id  = var.dns_zone
  name     = var.hostname
  type     = var.type
  ttl      = "300"
  records  = var.records
}
