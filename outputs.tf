output "master_public" {
  value = aws_instance.master.public_ip
}

output "master_dns" {
  value = aws_instance.master.public_dns
}

output "master_private" {
  value = aws_instance.master.private_ip
}

output "node_1_private" {
  value = aws_instance.node_1.private_ip
}

output "node_1_public" {
  value = aws_instance.node_1.public_ip
}

output "node_2_private" {
  value = aws_instance.node_2.private_ip
}

output "node_2_public" {
  value = aws_instance.node_2.public_ip
}

output "node_3_private" {
  value = aws_instance.node_3.private_ip
}

output "node_3_public" {
  value = aws_instance.node_3.public_ip
}
