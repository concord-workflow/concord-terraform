resource "aws_ec2_fleet" "main" {
  type                               = var.ec2_fleet_type
  tags                               = merge({ Name = var.ec2_fleet_name }, var.tags, var.ec2_fleet_tags)
  terminate_instances                = var.ec2_terminate_instances
  excess_capacity_termination_policy = var.ec2_fleet_excess_capacity_termination_policy

  target_capacity_specification {
    default_target_capacity_type     = var.ec2_fleet_default_capacity_type
    total_target_capacity            = var.ec2_fleet_target_capacity
    on_demand_target_capacity        = var.ec2_fleet_on_demand_target_capacity
    spot_target_capacity             = var.ec2_fleet_spot_target_capacity
  }

  launch_template_config {

    override {
      max_price                    = var.ec2_fleet_max_spot_price
    }

    launch_template_specification {
      launch_template_id             = aws_launch_template.main.id
      version                        = "$Latest"
    }
  }
}
