locals {
  domain_name = "velz3n.com"
  subdomain   = ["app", "app1"]
}

resource "aws_route53_zone" "velz3n" {
  name = local.domain_name
}

resource "aws_acm_certificate" "cert" {
  domain_name               = local.domain_name
  validation_method         = "DNS"
  subject_alternative_names = formatlist("%s.%s", local.subdomain, local.domain_name)

  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_route53_record" "records" {
#   for_each = {
#     for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = aws_route53_zone.velz3n.zone_id

# }

# resource "aws_acm_certificate_validation" "cert" {
#   certificate_arn         = aws_acm_certificate.cert.arn
#   validation_record_fqdns = [for record in aws_route53_record.records : record.fqdn]
# }