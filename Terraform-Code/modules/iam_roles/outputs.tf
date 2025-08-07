output "iam_role_name" {
  value = aws_iam_role.role.name
}

output "instance_profile_name" {
  value = aws_iam_instance_profile.ec2_instance_profile.name
}
