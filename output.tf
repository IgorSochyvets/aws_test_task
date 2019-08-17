#output "instance_ids" {
#    value = ["${aws_instance.my_webserver.*.public_ip}"]
#}

output "elb_dns_name" {
  value = "${aws_elb.example.dns_name}"
}
