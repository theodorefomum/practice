resource "aws_eks_cluster" "max_cluster" {
  name     = "max_prod_cluster"
  role_arn = aws_iam_role.eks-iam-role.arn

  vpc_config {
    subnet_ids = [aws_subnet.max_sbn-priv.id, aws_subnet.max_sbn-priv1.id]
  }
  depends_on = [
    aws_iam_role.eks-iam-role,
  ]
}

resource "aws_iam_role" "workernodes" {
  name = "eks-node-group-example"

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

resource "aws_eks_node_group" "worker-node-group" {
  cluster_name    = aws_eks_cluster.max_cluster.name
  node_group_name = "devopsthehardway-workernodes"
  node_role_arn   = aws_iam_role.workernodes.arn
  subnet_ids      = [aws_subnet.max_sbn-priv.id, aws_subnet.max_sbn-priv1.id]
  instance_types  = ["t2.small"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    #aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role" "eks-iam-role" {
  name = "devopsthehardway-eks-iam-role"

  path = "/"

  assume_role_policy = <<EOF
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
EOF
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-iam-role.name
}
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-EKS" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-iam-role.name
}


resource "aws_route_table_association" "public_association" {
  subnet_id     = aws_subnet.max_sbn-pub.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "public_association1" {
  subnet_id     = aws_subnet.max_sbn-pub1.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "private_association" {
  subnet_id     = aws_subnet.max_sbn-priv1.id
  route_table_id = aws_route_table.private_route.id
}

resource "aws_route_table_association" "private_association1" {
  subnet_id     = aws_subnet.max_sbn-priv.id
  route_table_id = aws_route_table.private_route.id
}

resource "aws_vpc" "max_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "max_vpc"
  }
}

resource "aws_subnet" "max_sbn-pub" {
  vpc_id            = aws_vpc.max_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "max_sbn-pub1" {
  vpc_id            = aws_vpc.max_vpc.id
  cidr_block        = "10.0.50.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "max_sbn-priv" {
  vpc_id            = aws_vpc.max_vpc.id
  cidr_block        = "10.0.17.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "max_sbn-priv"
  }
}

resource "aws_subnet" "max_sbn-priv1" {
  vpc_id            = aws_vpc.max_vpc.id
  cidr_block        = "10.0.67.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "max_sbn-priv"
  }
}

resource "aws_internet_gateway" "max-gw" {
  vpc_id = aws_vpc.max_vpc.id
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.max_sbn-pub.id
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.max_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.max-gw.id
  }
}

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.max_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow http inbound traffic"
  vpc_id      = aws_vpc.max_vpc.id

  ingress {
    description      = "http from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "http from VPC"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "http from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "allow_http"
  }
}
