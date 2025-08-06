/* data "csvdecode" "rules" {
  content = file("${path.module}/rules.csv")
}
*/

locals {
  csv_content = file("${path.module}/rules.csv")
  rules       = csvdecode(local.csv_content)
}

resource "aws_security_group" "main" {
  name   = "${var.project_name}-sg"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = local.rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = [ingress.value.cidr_block]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}