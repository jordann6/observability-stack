variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "observability-stack"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "instance_type" {
  description = "Worker node instance type. t3.medium is the practical floor for kube-prometheus-stack."
  type        = string
  default     = "t3.medium"
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "environment" {
  description = "Environment name, stamped on every resource via provider default_tags"
  type        = string
  default     = "demo"
}

variable "cost_center" {
  description = "Chargeback allocation code (finops.rego expects the cc-NNNN format)"
  type        = string
  default     = "cc-0001"

  validation {
    condition     = can(regex("^cc-[0-9]{4}$", var.cost_center))
    error_message = "cost_center must match cc-NNNN (four digits), e.g. cc-0001."
  }
}

variable "tags" {
  description = "Extra tags merged onto resources (base tags come from provider default_tags)"
  type        = map(string)
  default = {
    Project   = "observability-stack"
    ManagedBy = "terraform"
    Lifecycle = "deploy-demo-destroy"
  }
}
