# output "instance_public_ip" {
#   description = "ID of the EC2 instance"
#   value       = aws_instance.app_server.public_ip
# }

# output "iam_role_name" {
#   description = "ID of the EC2 instance"
#   value       = aws_iam_role.instance_role.name
# }

output "lb_dns_name" {
  description = "dns name of the loadbalancer to be accessed"
  value       = aws_lb.loadbalancer.dns_name
}