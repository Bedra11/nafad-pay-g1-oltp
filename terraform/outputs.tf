output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.nafadpay_ec2.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.nafadpay_ec2.public_dns
}

output "ec2_instance_id" {
  description = "Instance ID of the EC2"
  value       = aws_instance.nafadpay_ec2.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.nafadpay_sg.id
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i <your-key.pem> ubuntu@${aws_instance.nafadpay_ec2.public_ip}"
}
