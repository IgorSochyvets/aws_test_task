provider "aws" {
	region = "eu-central-1"
}

/*
## Creating EC2 instance (AMI Linux) and install nginx and sync index.html from s3 bucket 
resource "aws_instance" "my_webserver" {
	ami = "${lookup(var.amis,var.region)}"
	instance_type = "t2.micro"
	vpc_security_group_ids = [aws_security_group.my_webserver.id] 
	iam_instance_profile = "${aws_iam_instance_profile.test_profile.name}"
	user_data = <<EOF
#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install nginx1.12 -y
sudo rm /usr/share/nginx/html/index.html
sudo aws s3 sync s3://${aws_s3_bucket.b.id} /usr/share/nginx/html
sudo chkconfig nginx on
sudo systemctl start nginx	
EOF

  tags = {
    Name = "My Web Server build by Terraform"
}
}

*/

## Security Group (http) creating
resource "aws_security_group" "my_webserver" {
  name        = "WebServer security Group"
  description = "My security group"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "My Security Group"
}
}




## S3 bucket creating
resource "aws_s3_bucket" "b" {
  bucket = "my-bucket-for-test2019"
  acl    = "public-read"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

## Coping "index.html" to s3 bucket
resource "aws_s3_bucket_object" "b_object" {
  key                    = "index.html"
  bucket                 = "${aws_s3_bucket.b.id}"
  source                 = "index.html"
  server_side_encryption = "aws:kms"
}

## IAM role creating 
resource "aws_iam_role" "test_role" {
  name = "test_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
      tag-key = "tag-value"
  }
}

## Create EC2 Instance Profile
resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = "${aws_iam_role.test_role.name}"
}

## Adding IAM Policies
resource "aws_iam_role_policy" "test_policy" {
  name = "test_policy"
  role = "${aws_iam_role.test_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

## Creating Launch Configuration
resource "aws_launch_configuration" "example" {
  image_id               = "${lookup(var.amis,var.region)}"
  instance_type          = "t2.micro"
  security_groups        = ["${aws_security_group.my_webserver.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.test_profile.name}"
  user_data = <<EOF
#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install nginx1.12 -y
sudo rm /usr/share/nginx/html/index.html
sudo aws s3 sync s3://${aws_s3_bucket.b.id} /usr/share/nginx/html
sudo systemctl start nginx
EOF

    lifecycle {
    create_before_destroy = true
  }
}

## Creating AutoScaling Group
resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.example.id}"
  availability_zones = ["eu-central-1a", "eu-central-1b"]
  min_size = 2
  max_size = 10
  load_balancers = ["${aws_elb.example.name}"]
  health_check_type = "ELB"
  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}

## Security Group for ELB
resource "aws_security_group" "elb" {
  name = "terraform-example-elb"
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

### Creating ELB
resource "aws_elb" "example" {
  name = "terraform-asg-example"
  security_groups = ["${aws_security_group.elb.id}"]
  availability_zones = ["eu-central-1a", "eu-central-1b"]
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:80/"
  }
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "80"
    instance_protocol = "http"
  }
}


