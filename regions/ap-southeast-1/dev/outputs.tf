output "default_vpc_id" {
  value = aws_default_vpc.default.id
}

output "default_subnet_ids" {
  value = [
    for subnet in aws_default_subnet.default_subnets : subnet.id
  ]
}

# output "rds_cluster_endpoint" {
#   value = module.rds_cluster.cluster_endpoint
#   description = "Cluster endpoint"
# }

output "alb_target_group_arn" {
  value = module.alb.target_groups["http-request"].arn
}