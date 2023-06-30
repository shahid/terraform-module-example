variable "env" {
  description = "Environment in which infra needs to be provissione"
  type 	      = string
  default     = "development"
}
variable "client" {
  description = "Organization name"
  type        = string
  default     = "organization"
}
variable "account_id" {
  description = "AWS account ID"
  type	      = string
  default     = "000000000000"
}
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}
variable "vpc_name" {
  description = "Name of VPC"
  type        = string
}
#variable "tenancy" {
#  type        = string
#}
#variable "availability_zone1" {
#  description = "AZ 1"
#  type        = string
#}
#variable "availability_zone2" {
#  description = "AZ 2"
#  type        = string
#}

variable "azs" {
 type        = list(string)
 description = "Availability Zones"
 default     = ["us-east-1a", "us-east-1c", "us-east-1d"]
}
variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}
variable "public_subnet_eks_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values for eks"
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}
variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}
variable "private_subnet_eks_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.0.31.0/24", "10.0.32.0/24", "10.0.33.0/24"]
}
variable "private_subnet_rds_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.0.41.0/24", "10.0.42.0/24", "10.0.43.0/24"]
}
#variable "subnet1_cidr" {
#  description = "Subnet1 CIDR"
#  type        = string
#}
#variable "subnet1_name" {
#  description = "Public Subnet Name"
#  type        = string
#}
#variable "subnet2_cidr" {
#  description = "Subnet2 CIDR"
#  type        = string
#}
#variable "subnet2_name" {
#  description = "Public Subnet Name"
#  type        = string
#}
#variable "subnet3_cidr" {
#  description = "Subnet3 CIDR"
#  type        = string
#}
#variable "subnet3_name" {
#  description = "Private Subnet Name"
#  type        = string
#}
#variable "subnet4_cidr" {
#  description = "Subnet4 CIDR"
#  type        = string
#}
#variable "subnet4_name" {
#  description = "Private Subnet Name"
#  type        = string
#}
#variable "subnet5_cidr" {
#  description = "Subnet5 CIDR"
#  type        = string
#}
#variable "subnet5_name" {
#  description = "Private Subnet Name"
#  type        = string
#}
#variable "subnet6_cidr" {
#  description = "Subnet6 CIDR"
#  type        = string
#}
#variable "subnet6_name" {
#  description = "Private Subnet Name"
#  type        = string
#}
#variable "subnet7_cidr" {
#  description = "Subnet7 CIDR"
#  type        = string
#}
#variable "subnet7_name" {
#  description = "Private Subnet Name"
#  type        = string
#}
#variable "subnet8_cidr" {
#  description = "Subnet9 CIDR"
#  type        = string
#}
#variable "subnet8_name" {
#  description = "Private Subnet Name"
#  type        = string
#}
#variable "subnet9_cidr" {
#  description = "Subnet9 CIDR"
#  type        = string
#}
#variable "subnet9_name" {
#  description = "Private Subnet Name"
#  type        = string
#}
#variable "subnet10_cidr" {
#  description = "Subnet10 CIDR"
#  type        = string
#}
#variable "subnet10_name" {
#  description = "Private Subnet Name"
#  type        = string
#}
variable "gw_name" {
  description = "Internet gateway Name"
  type        = string
}
variable "nat_name" {
  description = "Nat gateway Name"
  type        = string
}
variable "rtbprivate_name" {
  description = "Private route table name"
  type        = string
}
variable "rtbpublic_name" {
  description = "Public route table name"
  type        = string
}
variable "s3-flowlog-bucket-name" {
  description = "S3 bucket for VPC flowlogs"
  type        = string
}
variable "flowlog_name" {
  description = "S3 bucket for VPC flowlogs"
  type        = string
}
