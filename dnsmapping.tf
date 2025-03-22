data "aws_route53_zone" "main" {
  name         = "atindra.in"
  private_zone = false
}

resource "aws_route53_record" "subdomainbackend" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "demovpcbackend.atindra.in"
  type    = "A"
  ttl     = 300
  records = [aws_instance.ec2_public.public_ip]
}

resource "aws_route53_record" "subdomainfrontend" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "demovpcfrontend.atindra.in"
  type    = "A"
  ttl     = 300
  records = [aws_instance.ec2_instance.public_ip]
}