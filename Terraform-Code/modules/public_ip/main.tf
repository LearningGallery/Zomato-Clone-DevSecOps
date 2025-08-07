resource "aws_eip" "eip" {
  #vpc = true
  domain   = "vpc"
  tags = {
    Name = "${var.project_name}-eip"
  }
}