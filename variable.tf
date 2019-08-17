variable "region" {
  description = "AWS region for hosting our network"
  default = "eu-central-1"
}

variable "amis" {
  description = "Base AMI to launch the instances"
  default = {
  eu-central-1 = "ami-0cc293023f983ed53"
  }
}
