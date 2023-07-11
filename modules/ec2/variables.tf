variable "ami" {
  type = map(string)
  default = {
    "us-east-1" = "ami-04169656fea786776"
    "us-west-1" = "ami-006fce2a9625b177f"
  }
}

variable "instance_count" {
  default = "2"
}

variable "instance_type" {
  default = "t2.nano"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "db_private_subnets" {
  type        = list(any)
  description = "Private Subnets for EKS Worker Nodes"
}

variable "env" {
  description = "Environment in which infra needs to be provision"
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
variable "key_name" {
  description = "SSH key"
  type	      = string
  default     = ""
}
