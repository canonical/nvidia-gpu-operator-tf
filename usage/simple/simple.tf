module "nvidia_gpu_operator" {
  source = "../../module"

  namespace               = "gpu-operator"
  helm_version            = "v25.3.2"
  operator_defaultRuntime = "containerd"
  driver_enabled          = true
  # driver_version          = "570.148.08"
  mig_strategy            = "single" # Use "mixed" better. This is just to test a different value than TF default 
  dcgmExporter_enabled    = true
}
