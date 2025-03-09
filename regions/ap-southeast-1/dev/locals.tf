locals {
  default = {
    vpc_id = data.aws_vpc.default.id

    availability_zones = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]

    subnets = {
      ap1 = {
        availability_zone = "ap-southeast-1a"
        tags = {
          Name = "default-subnet-1"
        }
      }
      ap2 = {
        availability_zone = "ap-southeast-1b"
        tags = {
          Name = "default-subnet-2"
        }
      }
      ap3 = {
        availability_zone = "ap-southeast-1c"
        tags = {
          Name = "default-subnet-3"
        }
      }
    }

    tags = {
      Terraform = "true"
      Environment = "dev"
    }
  }

  iam_roles = {
    rds_archive_role = {
      name = "rds_archive_role"
      assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
          {
            Effect = "Allow",
            Principal = {
              Service = "rds.amazonaws.com"
            },
            Action = "sts:AssumeRole"
          }
        ]
      })

      inline_policy = {
        name = "rds_archive_policy"
        policy = jsonencode({
          Version = "2012-10-17",
          Statement = [
            {
              Effect = "Allow",
              Action = [
                "s3:*",
                "s3-object-lambda:*"
              ],
              Resource = "*"
            }
          ]
        })
      }

      tags  = {
        rds-policy  = "rds-archive-role"
      }
  }
  }
  

  networks = {

  }

  security_groups = {
    ec2_ansible = {
        name        = "ec2-ansible-sg"
        description = "Security group for EC2 Ansible"
        vpc_id      = local.default.vpc_id
        ingress_with_cidr_blocks = [
            {
                from_port   = 22
                to_port     = 22
                protocol    = "tcp"
                description = "SSH"
                cidr_blocks = data.aws_vpc.default.cidr_block 
            },
            {
                from_port   = 443
                to_port     = 443
                protocol    = "tcp"
                description = "HTTPS"
                cidr_blocks = data.aws_vpc.default.cidr_block 
            }
        ]
        egress_with_cidr_blocks  = [
            {
                from_port   = 0
                to_port     = 0
                protocol    = "-1"
                description = "All traffic"
                cidr_blocks = "0.0.0.0/0"
            }
        ]
    }
  }

  ec2_instances = {
    ec2_ansible = {
        name = "ec2-ansible"
        instance_type   = "t2.micro"
        ami             = "ami-047126e50991d067b"
        
        monitoring              = false
        vpc_security_group_ids  = ["sg-0f9e7f6c"]
        subnet_id               = "subnet-0f9e7f6c"
        
        tags = {
            Terraform   = "true"
            Environment = "dev"
            Owner       = "DevSecOps Team"
            Support     = "devsecops@techcombank.com.vn"
        }

    }
  }

  rds_cluster = {
    rds_cluster_postgres= {
      name         = "aurora-db-postgres"
      engine       = "aurora-postgresql"
      engine_version = "16.4"
      instances = {
        rds-instance-1 = {
          instance_class = "db.t3.medium"
        }
      }

      vpc_id               = local.default.vpc_id
      db_subnet_group_name = "default-db-subnet-group"
      security_group_rules = {
        postgres = {
          type        = "ingress"
          from_port   = 5432
          to_port     = 5432
          protocol    = "tcp"
          cidr_blocks = [ tostring(data.aws_vpc.default.cidr_block) ]
        }
      }

      storage_encrypted   = false
      apply_immediately   = true
      
      skip_final_snapshot = true

      monitoring_interval = 0

      master_username = "pdadmin"
      master_password = "Passw0rd12345"

      manage_master_user_password = false

      enabled_cloudwatch_logs_exports = []

      iam_roles = {
        "rds_archive_role" = {
          role_arn      = resource.aws_iam_role.rds_archive_role.arn
          feature_name  = "s3Export"
        }
      }


      tags = {
        backup-policy = "db-type1"
      }
    }
  }
}