resource "aws_eip" "public" {
  #vpc = true
  domain   = "vpc"
  tags = {
    Name = "${var.project_name}-eip"
  }
}