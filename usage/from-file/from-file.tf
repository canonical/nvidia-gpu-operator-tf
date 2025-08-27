module "nvidia_gpu_operator" {
  source = "../../module"

  mig_strategy            = "mixed" # It will be ignored. Yaml file values takes priority.
  helm_config_file_path   = "values.yaml"
}
