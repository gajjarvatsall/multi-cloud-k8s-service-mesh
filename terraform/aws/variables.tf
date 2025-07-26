variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "multi-cloud-eks"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "node_group_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 4
}

variable "node_group_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "node_instance_types" {
  description = "Instance types for the node group"
  type        = list(string)
  default     = ["t3.micro"]
}
