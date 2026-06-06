include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///terraform-aws-modules/rds/aws//?version=6.1.1"
}

dependency "vpc" {
  config_path = "../vpc"
  
  mock_outputs = {
    database_subnet_group_name = "mock-db-subnet-group"
  }
}

dependency "security_groups" {
  config_path = "../security-groups"
  
  mock_outputs = {
    security_group_id = "mock-sg-id-456"
  }
}

inputs = {
  identifier = "whiteleaf-metadata-db"

  engine               = "mysql"
  engine_version       = "8.0"
  family               = "mysql8.0" 
  major_engine_version = "8.0"
  instance_class       = "db.t4g.micro" 

  allocated_storage     = 20
  max_allocated_storage = 100

  db_name  = "greenhouse_metadata"
  username = "admin"
  password = "SecurePassword123!" 
  port     = "3306"

  db_subnet_group_name   = dependency.vpc.outputs.database_subnet_group_name
  vpc_security_group_ids = [dependency.security_groups.outputs.security_group_id]

  skip_final_snapshot    = true
  deletion_protection    = false
}