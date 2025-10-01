resource "aws_route53_record" "dns_public" {
  zone_id = var.zone_id
  name    = "sonarqube"
  type    = "A"
  ttl     = 15
  records = [var.public_ip]
}