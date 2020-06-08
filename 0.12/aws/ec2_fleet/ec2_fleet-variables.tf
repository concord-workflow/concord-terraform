variable "ec2_fleet_name" {
  type        = string
  description = "Name of the autoscaling group"
}

# ------------------------------------------------------------------------------------------
# Fleet capacity
# ------------------------------------------------------------------------------------------
variable "ec2_fleet_target_capacity" {
  type        = number
  default     = 1
  description = "The number of computes in the EC2 Fleet"
}

variable "ec2_fleet_default_capacity_type" {
  type        = string
  default     = "spot"
  description = "The default type of compute for this EC2 Fleet."
}

# ------------------------------------------------------------------------------------------
# On demand instances
# ------------------------------------------------------------------------------------------
variable "ec2_fleet_on_demand_target_capacity" {
  type        = number
  default     = 1
  description = "The number of on-demand computes in the EC2 Fleet"
}

# ------------------------------------------------------------------------------------------
# Spot instances
# ------------------------------------------------------------------------------------------
variable "ec2_fleet_spot_target_capacity" {
  type        = number
  default     = 0
  description = "The number of spot computes in the EC2 Fleet"
}

variable "ec2_fleet_max_spot_price" {
  type        = string
  description = "Max price per hour for a spot instance"
}

variable "ec2_fleet_excess_capacity_termination_policy" {
  type        = string
  default     = "termination"
  description = "Specify policies that the fleet should use to terminate its instances"
}

variable "ec2_fleet_type" {
  type        = string
  default     = "maintain"
  description = "Specify policies that the fleet should use to terminate its instances"
}

variable "ec2_terminate_instances" {
  type        = bool
  default     = true
  description = "Whether to terminate instances for an EC2 Fleet if it is deleted successfully."
}

variable "ec2_fleet_tags" {
  type        = map
  default     = {}
  description = "The created EC2 instances in the fleet will have these tags applied over the default ones (see main.tf)"
}
