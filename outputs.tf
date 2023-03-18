output "azs" {
  value = data.aws_availability_zones.azs.names
}

output "ec2_instance_ssh_id" {
  value = module.ec2_instance.id
}

output "ec2_instance_ssh_ip" {
  value = aws_eip.ssh_eip.public_ip
}