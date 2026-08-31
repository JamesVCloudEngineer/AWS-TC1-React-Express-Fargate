# ---------- Security Group for Jenkins EC2 ----------
resource "aws_security_group" "jenkins" {
  name        = "tc1-jenkins-sg"
  description = "Allow SSH and Jenkins web access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins Web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tc1-jenkins-sg"
  }
}

# ---------- IAM Role so Jenkins EC2 can push to ECR / deploy to ECS ----------
resource "aws_iam_role" "jenkins_ec2_role" {
  name = "tc1-jenkins-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr_power" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "jenkins_ecs_full" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "tc1-jenkins-instance-profile"
  role = aws_iam_role.jenkins_ec2_role.name
}

# ---------- SSH Key Pair (auto-generated) ----------
resource "tls_private_key" "jenkins_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "jenkins_key" {
  key_name   = "tc1-jenkins-key"
  public_key = tls_private_key.jenkins_key.public_key_openssh
}

resource "local_file" "jenkins_private_key" {
  content         = tls_private_key.jenkins_key.private_key_pem
  filename        = "${path.module}/tc1-jenkins-key.pem"
  file_permission = "0400"
}

# ---------- EC2 Instance running Jenkins ----------
resource "aws_instance" "jenkins" {
  ami                    = "ami-0453ec754f44f9a4a" # Amazon Linux 2023, us-east-1
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  key_name               = aws_key_pair.jenkins_key.key_name
  iam_instance_profile   = aws_iam_instance_profile.jenkins_profile.name
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker git java-21-amazon-corretto
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ec2-user

    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    yum install -y jenkins
    usermod -aG docker jenkins
    systemctl enable jenkins
    systemctl start jenkins
  EOF

  tags = {
    Name = "tc1-jenkins-server"
  }
}

# ---------- Output ----------
output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}
