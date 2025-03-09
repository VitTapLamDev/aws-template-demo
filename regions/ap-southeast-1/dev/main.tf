# resource "tls_private_key" "private_key" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# resource "aws_key_pair" "ec2_ansible_key_pair" {
#   key_name    = "ec2_key_pair"
#   public_key  = tls_private_key.private_key.public_key_openssh
# }

resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "default_subnets" {

  for_each = local.default.subnets

  availability_zone = each.value.availability_zone
  tags = merge(local.default.tags, each.value.tags)
}

resource "aws_db_subnet_group" "default" {
  name       = "default-db-subnet-group"
  subnet_ids = [for s in aws_default_subnet.default_subnets : s.id]

  tags = merge(local.default.tags, {Name = "default-db-subnet-group"})
}

resource "aws_iam_role" "rds_archive_role" {
  name                = local.iam_roles.rds_archive_role.name
  assume_role_policy  = local.iam_roles.rds_archive_role.assume_role_policy

  inline_policy {
    name    = local.iam_roles.rds_archive_role.inline_policy.name
    policy  = local.iam_roles.rds_archive_role.inline_policy.policy
  }

  tags = merge(local.default.tags, local.iam_roles.rds_archive_role.tags)
}

module "rds_cluster" {
  source  = "terraform-aws-modules/rds-aurora/aws"

  name           = local.rds_cluster.rds_cluster_postgres.name
  engine         = local.rds_cluster.rds_cluster_postgres.engine
  engine_version = local.rds_cluster.rds_cluster_postgres.engine_version
  
  instances = local.rds_cluster.rds_cluster_postgres.instances

  vpc_id               = local.rds_cluster.rds_cluster_postgres.vpc_id
  db_subnet_group_name = local.rds_cluster.rds_cluster_postgres.db_subnet_group_name
  
  security_group_rules = local.rds_cluster.rds_cluster_postgres.security_group_rules
  
  storage_encrypted   = local.rds_cluster.rds_cluster_postgres.storage_encrypted
  apply_immediately   = local.rds_cluster.rds_cluster_postgres.apply_immediately

  skip_final_snapshot = local.rds_cluster.rds_cluster_postgres.skip_final_snapshot
  
  monitoring_interval = local.rds_cluster.rds_cluster_postgres.monitoring_interval

  master_username = local.rds_cluster.rds_cluster_postgres.master_username
  master_password = local.rds_cluster.rds_cluster_postgres.master_password

  manage_master_user_password = local.rds_cluster.rds_cluster_postgres.manage_master_user_password

  iam_roles = local.rds_cluster.rds_cluster_postgres.iam_roles

  tags = merge(local.default.tags, local.rds_cluster.rds_cluster_postgres.tags)

  depends_on = [ resource.aws_default_subnet.default_subnets ]
}