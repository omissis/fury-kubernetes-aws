output "vpc" {
  value = "${aws_vpc.main.arn}"
}

output "public_subnets" {
  value = "${flatten(aws_subnet.public.*.id)}"
}

output "private_subnets" {
  value = "${flatten(aws_subnet.private.*.id)}"
}

output "bastion_private_ip" {
  value = "${flatten(aws_instance.bastion.*.private_ip)}"
}

output "bastion_public_ip" {
  value = "${flatten(aws_eip.bastion.*.public_ip)}"
}