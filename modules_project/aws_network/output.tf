# Add output variables
output "public_subnet_id" {
  value = aws_subnet.public_subnet[*].id
}

output "private_subnet_id" {
  value = aws_subnet.private_subnet[*].id
}

output "private_routetable_id" {
  value = aws_route_table.private_subnets[*].id
}

output "public_routetable_id" {
  value = aws_route_table.public_subnets[*].id
}

output "vpc_id" {
  value = aws_vpc.main.id
}
