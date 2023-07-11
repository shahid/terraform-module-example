data "template_file" "step-ssm-startup" {
template = file("./ssm-agent-installer.sh")
}

resource "aws_iam_role" "iam_role" {
  name = "ssm-role"   
  description = "The role for the developer resources EC2"
  #Terraform's "jsonencode" function converts a Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
    {
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid = ""
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    },
    ]
  }) 
  tags = {
  tag-key = "ec2-policy"
  }
}

resource "aws_iam_instance_profile" "instance_iam_profile" {
  name = "private-instance-profile"
  role = aws_iam_role.iam_role.name
}
 
#resource "aws_iam_policy" "policy" {
#  name        = "test-policy"
#  description = "A test policy"
#
#  policy = <<EOF
#{
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Action": [
#        "ec2:Describe*"
#      ],
#      "Effect": "Allow",
#      "Resource": "*"
#    }
#  ]
#}
#EOF
#}

resource "aws_iam_policy_attachment" "policy-attachment" {
  name = "policy-attachment"
  roles = [aws_iam_role.iam_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_security_group" "allow_ssh" {
  name        = "alow-ssh"
  vpc_id      = var.vpc_id
  description = "Allows SSH"
  # allow SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Environment = "dev"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "instance" {
  #count         = var.instance_count
  count         = length(var.db_private_subnets)
  ami           = lookup(var.ami,var.aws_region)
  instance_type = var.instance_type
  subnet_id     = element(var.db_private_subnets, count.index)
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  key_name      = var.key_name
  #key_name     = aws_key_pair.terraform-demo.key_name
  iam_instance_profile = aws_iam_instance_profile.instance_iam_profile.name
  user_data = data.template_file.step-ssm-startup.rendered

  tags = {
    Name  = "${var.client}-${var.env}-db-psqld-${count.index + 1 }"
    Created_By = "terraform"
    Environment = "${var.env}"
    Type	= "db"
  }
}
