output "dns_app_fqdn" {
    
    description = "fqdn output for app"
    value = aws_route53_record.app_fqdn.fqdn
    
}