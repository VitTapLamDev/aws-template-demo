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

# module "rds_cluster" {
#   source  = "terraform-aws-modules/rds-aurora/aws"

#   name           = local.rds_cluster.rds_cluster_postgres.name
#   engine         = local.rds_cluster.rds_cluster_postgres.engine
#   engine_version = local.rds_cluster.rds_cluster_postgres.engine_version
  
#   instances = local.rds_cluster.rds_cluster_postgres.instances

#   vpc_id               = local.rds_cluster.rds_cluster_postgres.vpc_id
#   db_subnet_group_name = local.rds_cluster.rds_cluster_postgres.db_subnet_group_name
  
#   security_group_rules = local.rds_cluster.rds_cluster_postgres.security_group_rules
  
#   storage_encrypted   = local.rds_cluster.rds_cluster_postgres.storage_encrypted
#   apply_immediately   = local.rds_cluster.rds_cluster_postgres.apply_immediately

#   skip_final_snapshot = local.rds_cluster.rds_cluster_postgres.skip_final_snapshot
  
#   monitoring_interval = local.rds_cluster.rds_cluster_postgres.monitoring_interval

#   master_username = local.rds_cluster.rds_cluster_postgres.master_username
#   master_password = local.rds_cluster.rds_cluster_postgres.master_password

#   manage_master_user_password = local.rds_cluster.rds_cluster_postgres.manage_master_user_password

#   iam_roles = local.rds_cluster.rds_cluster_postgres.iam_roles

#   tags = merge(local.default.tags, local.rds_cluster.rds_cluster_postgres.tags)

#   depends_on = [ resource.aws_default_subnet.default_subnets ]
# }

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"

  name                    = local.asg.name
  
  min_size                = local.asg.min_size
  max_size                = local.asg.max_size
  desired_capacity        = local.asg.desired_capacity
  vpc_zone_identifier     = local.asg.vpc_zone_identifier

  launch_template_name    = local.asg.launch_template_name
  launch_template_description = local.asg.launch_template_description

  update_default_version  = local.asg.update_default_version

  image_id                = local.asg.image_id
  instance_type           = local.asg.instance_type

  ebs_optimized           = local.asg.ebs_optimized
  enable_monitoring       = local.asg.enable_monitoring

  create_iam_instance_profile = local.asg.create_iam_instance_profile
  iam_role_name           = local.asg.iam_role_name
  iam_role_path           = local.asg.iam_role_path
  iam_role_description    = local.asg.iam_role_description
  iam_role_tags           = merge(local.default.tags, local.asg.iam_role_tags)
  iam_role_policies       = local.asg.iam_role_policies

  metadata_options        = local.asg.metadata_options

  traffic_source_attachments = local.asg.traffic_source_attachments
  placement               = local.asg.placement

  tags = merge(local.default.tags, local.asg.tags)

  depends_on = [ module.alb ]
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name                          = local.alb.name
  vpc_id                        = local.alb.vpc_id
  subnets                       = local.alb.subnets
  security_group_ingress_rules  = local.alb.security_group_ingress_rules
  security_group_egress_rules   = local.alb.security_group_egress_rules
  listeners                     = local.alb.listeners

  enable_deletion_protection    = local.alb.enable_deletion_protection

  target_groups                 = local.alb.target_groups

  tags = merge(local.default.tags, local.alb.tags)
}