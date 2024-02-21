provider "aws" {
  
}

# create default vpc if one does not exit
resource "aws_default_vpc" "default_vpc" {
 
  tags = {
    Name = "default vpc"
  }
}
 
 
# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {
}
 
 
# create a default subnet in the first az if one does not exit
resource "aws_default_subnet" "subnet_az1" {
  availability_zone = data.aws_availability_zones.available_zones.names[0]
}
 
# create a default subnet in the second az if one does not exit
resource "aws_default_subnet" "subnet_az2" {
  availability_zone = data.aws_availability_zones.available_zones.names[1]
}
 
# create security group for the web server
resource "aws_security_group" "webserver_security_group" {
  name        = "webserver security group"
  description = "enable http access on port 80"
  vpc_id      =  aws_default_vpc.default_vpc.id
 
  ingress {
    description      = "http access"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
 
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }
 
  tags   = {
    Name = "pritesh-webserver-sg"
  }
}
 
# create security group for the database
resource "aws_security_group" "database_security_group" {
  name        = "database security group"
  description = "enable mysql/aurora access on port 3306"
  vpc_id      =  aws_default_vpc.default_vpc.id
 
  ingress {
    description      = "postgresql/aurora access"
    from_port        = "5432"
    to_port          = "5432"
    protocol         = "tcp"
    security_groups  = [aws_security_group.webserver_security_group.id]
  }
 
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }
 
  tags   = {
 
    Name = "pritesh-db-sg"
  }
}
 
 
# create the subnet group for the rds instance
resource "aws_db_subnet_group" "database_subnet_group" {
  name         = "database subnets group"
  subnet_ids   = [aws_default_subnet.subnet_az1.id, aws_default_subnet.subnet_az2.id]
  description  = "subnets for database instance"
 
  tags   = {
    Name = "pritesh-db-subnet-group"
  }
}
 
 
# create the rds instance
resource "aws_db_instance" "db_instance" {
  engine                  = "aurora-postgresql"
  engine_version          = "15.4"
  multi_az                = false
  identifier              = "pritesh-db-rds-instance"
  username                = "postgres"
  password                = "demo1234!"
  instance_class          = "db.r5.2xlarge"
  allocated_storage       = 20
  max_allocated_storage   = 100
  db_subnet_group_name    = aws_db_subnet_group.database_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.webserver_security_group.id]
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  db_name                 = "priteshapplicationdb"
  skip_final_snapshot     = true
  storage_encrypted = true
  storage_type         = "gp3"
  kms_key_id = "arn:aws:kms:ap-south-1:266253954581:key/a9b8683b-1a29-44f9-ae57-26b484326306"
}