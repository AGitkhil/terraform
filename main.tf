provider "aws" {
  region  = "ap-south-1"
}
 
resource "aws_instance" "example_server" {
  ami           = "ami-0d980397a6e8935cd"
  instance_type = "t2.micro"
  subnet_id = "vpc-081e812ff62ba2ca5"
 
  tags = {
    Name = "Terraform"
  }
}