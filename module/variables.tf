variable "namespace" {
  description = "The Kubernetes namespace to install the GPU Operator in."
  type        = string
  default     = "gpu-operator"
}

variable "helm_version" {
  description = <<EOT
The version of the GPU Operator Helm chart to deploy.
NOTE: Not all GPU Operator releases have a Helm chart available 
Check with:

$ helm search repo nvidia/gpu-operator --versions
EOT

  type        = string
  default     = "v25.3.2"
}

variable "operator_defaultRuntime" {
  description = "Sets the default container runtime for the operator."
  type        = string
  default     = "containerd"
}

variable "driver_enabled" {
  description = "Enable or disable the NVIDIA driver component."
  type        = bool
  default     = true
}

variable "driver_usePrecompiled" {
  description = "Use pre-compiled driver packages."
  type        = bool
  default     = false
}

variable "driver_version" {
  description = <<EOT
The version of the NVIDIA driver to install.

Check drivers available per GPU operator release
https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/platform-support.html#gpu-operator-component-matrix
EOT

  type        = string
  default     = null
}

variable "driver_rdma_enabled" {
  description = "Enable RDMA configuration for the driver."
  type        = bool
  default     = false
}

variable "driver_rdma_useHostMofed" {
  description = "Use the host's MOFED (Mellanox OFED) instead of installing a new one."
  type        = bool
  default     = false
}

variable "mig_strategy" {
  description = "Strategy for Multi-Instance GPU (MIG) management: either 'none' or 'single'."
  type        = string
  default     = "mixed"
}

variable "mig_labels" {
  description = "Additional labels for MIG devices."
  type        = string
  default     = "[]"
}

variable "dcgmExporter_enabled" {
  description = "Enable the DCGM Exporter for GPU metrics."
  type        = bool
  default     = true # https://developer.nvidia.com/dcgm
}

variable "helm_config_file_path" {
  description = <<EOT
Path to a Helm values YAML file for additional configuration.

When this file is provided, its values will be merged with the chart's defaults.
However, values set directly in the Terraform module using the `set` argument will
take precedence and override any conflicting values in this YAML file.
EOT

  type        = string
  default     = null
}