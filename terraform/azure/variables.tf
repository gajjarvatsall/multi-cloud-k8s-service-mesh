variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "multi-cloud-aks"
}

variable "location" {
  description = "Azure location"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "multi-cloud-rg"
}

variable "node_count" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 2
}

variable "node_vm_size" {
  description = "VM size for the nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28.3"
}
