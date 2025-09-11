terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/helm/latest/docs
provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config" 
  }
}

# ---------------
# Just to keep the YAML clean and avoid nulls
locals {
  mig_block = merge(
    { strategy = var.mig_strategy },
    length(var.mig_labels) > 0 ? { labels = var.mig_labels } : {}
  )

  driver_rdma_block = {
    enabled      = var.driver_rdma_enabled
    useHostMofed = var.driver_rdma_useHostMofed
  }

  driver_block = merge(
    {
      enabled        = var.driver_enabled
      usePrecompiled = var.driver_usePrecompiled
      rdma           = local.driver_rdma_block
    },
    # Only include "version" when non-null/non-empty
    var.driver_version != null && trim(var.driver_version) != "" ? { version = var.driver_version } : {} 
  )

  inline_values = {
    operator = {
      defaultRuntime = var.operator_defaultRuntime
    }
    driver = local.driver_block
    mig    = local.mig_block
    dcgmExporter = {
      enabled = var.dcgmExporter_enabled
    }
  }
}

resource "helm_release" "nvidia_gpu_operator" {
  name       = "nvidia-gpu-operator"
  repository = "https://helm.ngc.nvidia.com/nvidia"
  chart      = "gpu-operator"
  create_namespace = true
  namespace  = var.namespace
  version    = var.helm_version

  # Pass optional file (if provided) + inline YAML
  # Prioritize values from the YAML over default and explicit terraform values
  values = compact([
    var.helm_config_file_path != null && var.helm_config_file_path != "" ? file(var.helm_config_file_path) : null,
    yamlencode(local.inline_values),
  ])

}