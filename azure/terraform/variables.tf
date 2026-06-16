variable "location" {
  description = "Azure region to deploy into"
  type        = string
  default     = "eastus"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "observability-stack"
}

variable "resource_group_name" {
  description = "Resource group to create for the cluster"
  type        = string
  default     = "observability-stack-rg"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version. Leave null to use the region default."
  type        = string
  default     = null
}

variable "vm_size" {
  description = "Worker node VM size. Standard_B2s is the practical floor for kube-prometheus-stack."
  type        = string
  default     = "Standard_B2s"
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    Project   = "observability-stack"
    ManagedBy = "terraform"
    Lifecycle = "deploy-demo-destroy"
  }
}
