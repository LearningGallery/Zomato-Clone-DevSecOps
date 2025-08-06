resource "aws_instance" "main" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.sg_id]
  key_name               = var.key_name
  associate_public_ip_address = true

  user_data = file("${path.module}/../../scripts/bootstrap.sh")

  tags = {
    Name = "${var.project_name}-instance"
  }
}