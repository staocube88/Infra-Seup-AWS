output "aws_control_plane_private_ip" {
  value = aws_instance.instance_control_plane.private_ip
}
