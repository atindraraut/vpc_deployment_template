# Update the A record for your domain in GoDaddy
resource "godaddy_domain_record" "a_record" {
  domain = "atindra.in"  # Replace with your domain
  name   = "learnterraform"             # Replace with the subdomain you want to update (e.g., "www" or "@" for root domain)
  type   = "A"
  data   = aws_instance.ec2_public.public_ip
  ttl    = 60  # Time-to-live, adjust as necessary
}