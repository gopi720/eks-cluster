terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
    }
  }
}
provider "aws" {
  region = "ap-south-1"
  access_key = var.accesskey
  secret_key = var.secretkey   
}
resource "aws_vpc" "airtelcare-vpc" {
  cidr_block =  "10.0.0.0/16"
  tags = {
    "Name" = "k8s-vpc"
  }
}
resource "aws_subnet" "airtelcare-subnet-1" {
  vpc_id = aws_vpc.airtelcare-vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    "Name" = "k8s-publicsubnet"
  }
}
resource "aws_subnet" "airtelcare-subnet-2" {
  vpc_id = aws_vpc.airtelcare-vpc.id
  cidr_block = "10.0.2.0/24"
  tags = {
    "Name" = "k8s-publicsubnet2"
  }
}
resource "aws_internet_gateway" "airtelcare-ig" {
    vpc_id = aws_vpc.airtelcare-vpc.id
    tags = {
      "Name" = "k8s-ig"
    }
}
resource "aws_route_table" "airtelcare-rt" {
  vpc_id = aws_vpc.airtelcare-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.airtelcare-ig.id
  }
}
resource "aws_route_table_association" "airtelcare-rtassoc" {
  subnet_id = aws_subnet.airtelcare-subnet-1.id
  route_table_id = aws_route_table.airtelcare-rt.id 
}
resource "aws_route_table_association" "airtelcare-rtassoc1" {
  subnet_id = aws_subnet.airtelcare-subnet-2.id
  route_table_id = aws_route_table.airtelcare-rt.id
}
 resource "aws_security_group" "airtelcare-sg" {
  vpc_id = aws_vpc.airtelcare-vpc.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
   from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }
}
resource "aws_iam_role" "k8s-cluster" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_role" "k8s-nodegroup" {
  name = "eks-nodegroup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "airtelcare-role" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role = aws_iam_role.k8s-cluster.name
}
resource "aws_iam_role_policy_attachment" "airtelcare-workernode" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role = aws_iam_role.k8s-nodegroup.name
}
resource "aws_iam_role_policy_attachment" "airtelcare-cni" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role = aws_iam_role.k8s-nodegroup.name
}
resource "aws_iam_role_policy_attachment" "airtelcare-crr" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role = aws_iam_role.k8s-nodegroup.name
}
resource "aws_eks_cluster" "airtelcare-cluster" {
  name = "k8scluster"
  role_arn = aws_iam_role.k8s-cluster.arn
  vpc_config {
    subnet_ids = [ aws_subnet.airtelcare-subnet-1.id , aws_subnet.airtelcare-subnet-2.id ]
  }
  depends_on = [ aws_iam_role_policy_attachment.airtelcare-role ]
}
resource "aws_eks_node_group" "eks-nodes" {
  cluster_name = aws_eks_cluster.airtelcare-cluster.name
  node_group_name = "k8s-nodes"
  node_role_arn = aws_iam_role.k8s-nodegroup.arn
  subnet_ids = [ aws_subnet.airtelcare-subnet-1.id , aws_subnet.airtelcare-subnet-2.id ]
  instance_types = ["t2.micro"]
  scaling_config {
    desired_size = 1 
    max_size = 1 
    min_size = 1 
  }
  depends_on = [ aws_iam_role_policy_attachment.airtelcare-cni , aws_iam_role_policy_attachment.airtelcare-crr , aws_iam_role_policy_attachment.airtelcare-workernode ]
}

