resource "aws_instance" "jenkins-server" {
  ami                    = "ami-0aa7d40eeae50c9a9"
  instance_type          = "t2.small"
  vpc_security_group_ids = ["${aws_security_group.jenkinssg.id}"]
  key_name               = "AYIMM"

  tags = {
    Name = "Jenkins-prod"
  }

  user_data = <<EOF
    #!/bin/bash
    yum update -y

    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
    yum upgrade -y
    amazon-linux-extras install java-openjdk11 -y
    yum install jenkins -y
    systemctl enable jenkins
    systemctl start jenkins

    sudo yum install git -y

    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
    sudo yum -y install terraform

    sudo curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.23.6/bin/linux/amd64/kubectl
    sudo chmod +x ./kubectl
    sudo mkdir -p $HOME/bin && sudo cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin

    # Install necessary packages for Docker
    sudo yum install -y docker
    sudo service docker start
    sudo usermod -aG docker $USER
    sudo chkconfig docker on
  EOF
}
resource "aws_security_group" "jenkinssg" {
  name        = "jenkinssg"
  description = "Allow SSH and HTTP Traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}