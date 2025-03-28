output "web_app_instance_public_ip" {
    value = aws_instance.web-app-instance.public_ip
    description = "Indirizzo IP pubblico dell'istanza web-app"
}