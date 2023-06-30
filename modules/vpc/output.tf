output "vpc_id" {
  value = aws_vpc.main.id
}
output "public_subnets_id" {
  value = aws_subnet.public_subnets.*.id
}

output "public_eks_subnets_id" {
  value = aws_subnet.public_eks_subnets.*.id
}

output "private_subnets_id" {
  value = aws_subnet.private_subnets.*.id
}

output "private_eks_subnets_id" {
  value = aws_subnet.private_eks_subnets.*.id
}

output "private_rds_subnets_id" {
  value = aws_subnet.private_rds_subnets.*.id
}

#output "public_subnet1_id" {
#  value = aws_subnet.public_subnet1.id
#}
#output "public_subnet2_id" {
#  value = aws_subnet.public_subnet2.id
#}
#output "private_subnet1_id" {
#  value = aws_subnet.private_subnet1.id
#}
#output "private_subnet2_id" {
#  value = aws_subnet.private_subnet2.id
#}
#output "private_subnet3_id" {
#  value = aws_subnet.private_subnet3.id
#}
#output "private_subnet4_id" {
#  value = aws_subnet.private_subnet4.id
#}
#output "private_subnet5_id" {
#  value = aws_subnet.private_subnet5.id
#}
#output "private_subnet6_id" {
#  value = aws_subnet.private_subnet6.id
#}
#output "private_subnet7_id" {
#  value = aws_subnet.private_subnet7.id
#}
#output "private_subnet8_id" {
#  value = aws_subnet.private_subnet8.id
#}
#output "public_subnet1_cidr" {
#  value = aws_subnet.public_subnet1.cidr_block
#}
#output "public_subnet2_cidr" {
#  value = aws_subnet.public_subnet2.cidr_block
#}
#output "private_subnet2_cidr" {
#  value = aws_subnet.private_subnet2.cidr_block
#}
#output "private_subnet1_cidr" {
#  value = aws_subnet.private_subnet1.cidr_block
#}
#output "private_subnet3_cidr" {
#  value = aws_subnet.private_subnet3.cidr_block
#}
#output "private_subnet4_cidr" {
#  value = aws_subnet.private_subnet4.cidr_block
#}
#output "private_subnet5_cidr" {
#  value = aws_subnet.private_subnet5.cidr_block
#}
#output "private_subnet6_cidr" {
#  value = aws_subnet.private_subnet6.cidr_block
#}
#output "private_subnet7_cidr" {
#  value = aws_subnet.private_subnet7.cidr_block
#}
#output "private_subnet8_cidr" {
#  value = aws_subnet.private_subnet8.cidr_block
#}
