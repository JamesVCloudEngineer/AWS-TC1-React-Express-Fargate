resource "aws_ecs_cluster" "main" {
  name = "tc1-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "tc1-cluster"
  }
}
