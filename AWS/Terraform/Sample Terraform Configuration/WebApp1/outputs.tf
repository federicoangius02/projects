output "alb_dns" {
  value = aws_lb.load_balancer.dns_name
}