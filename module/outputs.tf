output "release_name" {
  description = "The name of the Helm release."
  value       = helm_release.nvidia_gpu_operator.name
}

output "release_status" {
  description = "The status of the Helm release."
  value       = helm_release.nvidia_gpu_operator.status
}

output "operator_version" {
  description = "The configured version of the GPU Operator."
  value       = var.helm_version
}