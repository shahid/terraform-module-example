# IAM Role for EKS Cluster

resource "aws_iam_role" "eks_iam_role" {
  name               = var.eks_cluster_iam_role
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

#autoscaling policy for worker role
resource "aws_iam_policy" "eks_iam_autoscaling_workernode" {
  name        = var.eks_iam_autoscaling_workernode
  description = "autoscaling policy for worker role"

  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeLaunchTemplateVersions"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOT
}
#aws secret read policy for worker role
resource "aws_iam_policy" "eks_iam_secrets_read_workernode" {
  name        = var.eks_iam_secrets_read_workernode
  description = "secrets read policy for worker role"

  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds",
                "secretsmanager:ListSecrets"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOT
}

# IAM Policy Attachments

data "aws_iam_policy" "AmazonEKSClusterPolicy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy" "AmazonEKSVPCResourceController" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = data.aws_iam_policy.AmazonEKSClusterPolicy.arn
  role       = aws_iam_role.eks_iam_role.name
  depends_on = [
    aws_iam_role.eks_iam_role
  ]
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = data.aws_iam_policy.AmazonEKSVPCResourceController.arn
  role       = aws_iam_role.eks_iam_role.name
  depends_on = [
    aws_iam_role.eks_iam_role
  ]
}

resource "aws_kms_key" "eks_cluster_kms" {
  tags = {
    "Cluster" = "${var.cluster_name}"
  }
}

resource "aws_cloudwatch_log_group" "eks_controlplane_logs" {
  name = "/aws/eks/${var.cluster_name}/cluster"
}

# EKS Cluster

resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_iam_role.arn
  version  = var.cluster_version
  vpc_config {
    subnet_ids              = var.eks_public_subnets
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["${var.eks_public_access_cidr}"]
  }
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks_cluster_kms.arn
    }
    resources = ["secrets"]
  }
  # enabled_cluster_log_types = [ "api", "audit", "authenticator", "controllerManager", "scheduler" ]

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
    aws_kms_key.eks_cluster_kms,
    aws_cloudwatch_log_group.eks_controlplane_logs
  ]
}


# OIDC Provider

data "tls_certificate" "eks_cluster_tls" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

# Provides an IAM OpenID Connect provider
resource "aws_iam_openid_connect_provider" "eks_cluster_openid" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_cluster_tls.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}



# VPC CNI Role - Is the plugin for pod networking in Amazon EKS clusters.

data "aws_iam_policy_document" "AmazonEKSCNIRoleFederation" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_cluster_openid.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }
    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_cluster_openid.arn]
      type        = "Federated"

    }
  }
}


resource "aws_iam_role" "AmazonEKSCNIRole" {
  assume_role_policy = data.aws_iam_policy_document.AmazonEKSCNIRoleFederation.json
  name               = "AmazonEKSCNIRole"
}

resource "aws_iam_role_policy_attachment" "AmazonEKSCNIPolicyAttachment" {
  role       = aws_iam_role.AmazonEKSCNIRole.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}


# EKS Worker Node Role
resource "aws_iam_role" "AmazonEKSNodeRole" {
  name = "AmazonEKSNodeRole"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.AmazonEKSNodeRole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerautoscalingpolicy" {
  policy_arn = aws_iam_policy.eks_iam_autoscaling_workernode.arn
  role       = aws_iam_role.AmazonEKSNodeRole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerSecretsReadpolicy" {
  policy_arn = aws_iam_policy.eks_iam_secrets_read_workernode.arn
  role       = aws_iam_role.AmazonEKSNodeRole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.AmazonEKSNodeRole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.AmazonEKSNodeRole.name
}


# Cluster Autoscaler Role

data "aws_iam_policy_document" "AmazonEKSClusterAutoscalerFederation" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_cluster_openid.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }
    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_cluster_openid.arn]
      type        = "Federated"

    }
  }
}

resource "aws_iam_role" "AmazonEKSClusterAutoscalerRole" {
  assume_role_policy = data.aws_iam_policy_document.AmazonEKSClusterAutoscalerFederation.json
  name               = "AmazonEKSClusterAutoscalerRole"
}

resource "aws_iam_role_policy" "AmazonEKSClusterAutoscalerPolicy" {
  name   = "AmazonEKSClusterAutoscalerPolicy"
  role   = aws_iam_role.AmazonEKSClusterAutoscalerRole.name
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeLaunchTemplateVersions"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
  depends_on = [
  aws_iam_role.AmazonEKSClusterAutoscalerRole]
}



# EKS Worker Node - Managed Node Group

resource "aws_eks_node_group" "eks_managed_worker_nodes" {
  node_role_arn   = aws_iam_role.AmazonEKSNodeRole.arn
  cluster_name    = var.cluster_name
  node_group_name = var.eks_managed_worker_nodes_name
  subnet_ids      = var.eks_private_subnets
  ami_type        = var.eks_managed_worker_nodes_ami_type
  disk_size       = var.eks_managed_worker_nodes_disk_size
  instance_types  = var.eks_managed_worker_nodes_instance_type

  scaling_config {
    desired_size = var.eks_managed_worker_nodes_desired_size
    max_size     = var.eks_managed_worker_nodes_max_size
    min_size     = var.eks_managed_worker_nodes_min_size
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_eks_cluster.eks_cluster
  ]
  tags = {
    Name = "${var.cluster_name}-worker-node"
  }
}

# AmazonEKSLoadBalancerControllerRole

data "aws_iam_policy_document" "AmazonEKSLoadBalancerControllerFederation" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_cluster_openid.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_cluster_openid.arn]
      type        = "Federated"

    }
  }
}

resource "aws_iam_role" "AmazonEKSLoadBalancerControllerRole" {
  assume_role_policy = data.aws_iam_policy_document.AmazonEKSLoadBalancerControllerFederation.json
  name               = "AmazonEKSLoadBalancerControllerRole"
}

resource "aws_iam_policy" "AmazonEKSLoadBalancerControllerPolicy" {
  name = "AmazonEKSLoadBalancerControllerPolicy"
  # role = "${aws_iam_role.AmazonEKSLoadBalancerControllerRole.name}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole",
                "ec2:DescribeAccountAttributes",
                "ec2:DescribeAddresses",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeInternetGateways",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeInstances",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeTags",
                "ec2:GetCoipPoolUsage",
                "ec2:DescribeCoipPools",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeLoadBalancerAttributes",
                "elasticloadbalancing:DescribeListeners",
                "elasticloadbalancing:DescribeListenerCertificates",
                "elasticloadbalancing:DescribeSSLPolicies",
                "elasticloadbalancing:DescribeRules",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeTargetGroupAttributes",
                "elasticloadbalancing:DescribeTargetHealth",
                "elasticloadbalancing:DescribeTags"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cognito-idp:DescribeUserPoolClient",
                "acm:ListCertificates",
                "acm:DescribeCertificate",
                "iam:ListServerCertificates",
                "iam:GetServerCertificate",
                "waf-regional:GetWebACL",
                "waf-regional:GetWebACLForResource",
                "waf-regional:AssociateWebACL",
                "waf-regional:DisassociateWebACL",
                "wafv2:GetWebACL",
                "wafv2:GetWebACLForResource",
                "wafv2:AssociateWebACL",
                "wafv2:DisassociateWebACL",
                "shield:GetSubscriptionState",
                "shield:DescribeProtection",
                "shield:CreateProtection",
                "shield:DeleteProtection"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupIngress"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSecurityGroup"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags"
            ],
            "Resource": "arn:aws:ec2:*:*:security-group/*",
            "Condition": {
                "StringEquals": {
                    "ec2:CreateAction": "CreateSecurityGroup"
                },
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags",
                "ec2:DeleteTags"
            ],
            "Resource": "arn:aws:ec2:*:*:security-group/*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:DeleteSecurityGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:CreateTargetGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:DeleteListener",
                "elasticloadbalancing:CreateRule",
                "elasticloadbalancing:DeleteRule"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:RemoveTags"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
            ],
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:RemoveTags"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
                "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
                "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
                "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:ModifyLoadBalancerAttributes",
                "elasticloadbalancing:SetIpAddressType",
                "elasticloadbalancing:SetSecurityGroups",
                "elasticloadbalancing:SetSubnets",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:ModifyTargetGroup",
                "elasticloadbalancing:ModifyTargetGroupAttributes",
                "elasticloadbalancing:DeleteTargetGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:DeregisterTargets"
            ],
            "Resource": "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:SetWebAcl",
                "elasticloadbalancing:ModifyListener",
                "elasticloadbalancing:AddListenerCertificates",
                "elasticloadbalancing:RemoveListenerCertificates",
                "elasticloadbalancing:ModifyRule"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AmazonEKSLoadBalancerControllerRoleAttachment" {
  policy_arn = aws_iam_policy.AmazonEKSLoadBalancerControllerPolicy.arn
  role       = aws_iam_role.AmazonEKSLoadBalancerControllerRole.name
  depends_on = [
    aws_iam_role.AmazonEKSLoadBalancerControllerRole
  ]
}

resource "aws_iam_role_policy_attachment" "eks_iam_roleAttachment" {
  policy_arn = aws_iam_policy.AmazonEKSLoadBalancerControllerPolicy.arn
  role       = aws_iam_role.eks_iam_role.name
  depends_on = [
    aws_iam_role.eks_iam_role
  ]
}
