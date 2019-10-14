output "nginx_reverse_proxy_server" {
  value = "http://${aws_elb.web.dns_name}"
}

output "db_instance_address" {
  value = "${aws_db_instance.default.address}"
}

output "app_server_address" {
  value = "http://${aws_instance.app.public_ip}:5000"
}
