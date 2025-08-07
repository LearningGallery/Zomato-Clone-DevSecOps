resource "aws_instance" "ec2" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.sg_id]
  key_name               = var.key_name
  associate_public_ip_address = true
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = 0.0499
    }
  }

  ebs_block_device {
    device_name           = "/dev/xvdf"
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  iam_instance_profile = var.iam_instance_profile
  #iam_instance_profile = module.iam_roles.instance_profile_name
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  user_data = file("${path.module}/../../scripts/bootstrap.sh")

  tags = {
    Name = "${var.project_name}-instance"
  }
}