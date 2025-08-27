# Terraform NVIDIA GPU Operator Module

This module deploys the NVIDIA GPU Operator using its official Helm chart. 
It provides a flexible way to install and configure the operator in a Kubernetes cluster, allowing for easy management of NVIDIA GPUs.

More information at
[Spec: FE0001 - Terraform for Kubernetes Helm NVIDIA GPU Operator (Canonical INTERNAL)](https://docs.google.com/document/d/1psrFPwLcBbr1mx4SSUL1VBfulS1_wQ1FBtw-EcpNoZQ/edit?usp=sharing)


# Features
Installs the NVIDIA GPU Operator via the Helm provider.
Configurable parameters for the operator, driver, MIG (Multi-Instance GPU), and other components.
Supports an optional Helm values YAML file for advanced configuration

# Usage

To use this module, include it in your main Terraform configuration (`main.tf`) and provide the necessary input variables:
Examples under `usage` folder

```bash
cd usage
cd simple

tofu init
tofu apply
# [..]

# See expected outputs in .out file
```


## Inputs

| Variable                 | Description                                                                                                                                                                                                                                                                                                                              | Type   | Default      | Required |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | ------------ | -------- |
| namespace                | Namespace to install the operator                                                                                                                                                                                                                                                                                                        | string | gpu-operator | no       |
| helm_version             | Helm chart version to deploy. [Latest operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/release-notes.html). [Latest helm](https://nvidia.github.io/gpu-operator/index.yaml)                                                                                                                                 | string | v25.3.2      | no       |
| operator_defaultRuntime  | Container runtime used                                                                                                                                                                                                                                                                                                                   | string | containerd   | no       |
| driver_enabled           | Should the operator install or not the GPU driver.                                                                                                                                                                                                                                                                                       | bool   | true         | no       |
| driver_usePrecompiled    | Should the operator use a precompiled driver or build during installation.                                                                                                                                                                                                                                                               | bool   | false        | no       |
| driver_version           | GPU Driver version. Comes from NVIDIA repositories. If unset, the GPU operator will use its default one for that release. [Read more](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/platform-support.html#gpu-operator-component-matrix)                                                                           | string | null         | no       |
| driver_rdma_enabled      | Enable RDMA (Remote Direct Memory Access). Used for Infiniband networks or Ethernet with RoCE. Set to false, so that the NVIDIA **Network** Operator takes care of enabling it, instead of the GPU operator.                                                                                                                             | bool   | false        | no       |
| driver_rdma_useHostMofed | Use the host's MOFED instead of installing a new one.                                                                                                                                                                                                                                                                                    | bool   | false        | no       |
| mig_strategy             | MIG Strategy. Using `mixed` allows Kubernetes user to differentiate between (a) GPU MIG slice `nvidia.com/mig-<slice_count>g.<memory_size>gb` and (b) GPU full device `nvidia.com/gpu` when requesting a GPU for a pod                                                                                                                   | string | mixed        | no       |
| mig_labels               | Enable a MIG profile to specified Kubernetes workers. eg `[k8s-worker-a=all-1g.12gb, k8s-worker-b=all-balanced]`. Read more about [MIG labels](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-operator-mig.html) and [MIG profiles](https://docs.nvidia.com/datacenter/tesla/mig-user-guide/#h100-mig-profiles) | string | []           | no       |
| dcgmExporter_enabled     | Enable the DCGM Exporter for GPU metrics.                                                                                                                                                                                                                                                                                                | bool   | true         | no       |
| helm_config_file_path    | Optional parameter to directly provide a full yaml configuration file for GPU operator. Useful for end-users that need extra configuration parameters that are not yet exposed. Values set in this file will merge with default and explicit Terraform values. The yaml file values take priority over Terraform values.                 | string | null         | no       | 

> NOTE (`mig_labels`): This initial terraform version does not support custom MIG labels like [this one](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-operator-mig.html#example-custom-mig-configuration-during-installation). If needed has to be configured outside the terraform.


> NOTE (`dcgmExporter_enabled`): On the initial version it only enables the exporter, but it does not integrate the exporter metrics with a scrapper and also does not create a dashboard for it.


### How to integrate the NVIDIA GPU Operator dcgmExporter with COS
```bash
NODE_PORT=32094

kubectl apply -f - << EOF
# https://docs.nvidia.com/datacenter/cloud-native/gpu-telemetry/dcgm-exporter.html
apiVersion: v1
kind: Service
metadata:
 annotations:
   prometheus.io/scrape: "true"
 labels:
   app: nvidia-dcgm-exporter-cos
 name: nvidia-dcgm-exporter-cos
 namespace: gpu-operator
spec:
 ipFamilies:
 - IPv4
 ipFamilyPolicy: SingleStack
 ports:
 - name: gpu-metrics
   port: 9400
   protocol: TCP
   targetPort: 9400
   nodePort: $NODE_PORT
 selector:
   app: nvidia-dcgm-exporter
 sessionAffinity: None
 type: NodePort
status:
 loadBalancer: {}
EOF


echo "Get the IPs for the GPU machines on the OAM network were COS is"


# NOTE: Not scalable. We should have a say in COS to scrape multiple targets with a single application. Similar to old LMA prometheus https://charmhub.io/prometheus/configurations#scrape-jobs 
juju deploy -m cos prometheus-scrape-target-k8s prometheus-scrape-target-gpu-a \
   --channel 1/stable \
   --base ubuntu@20.04 \
   --config job_name=gpu-metrics-gpu-1 \
   --config labels="dns_name:'k8s-cluster-ai-1.maas',kubernetes_node:'k8s-cluster-ai-1'" \
   --config scheme=http \
   --config metrics_path="/metrics" \
   --config tls_config_insecure_skip_verify=true \
   --config targets="10.0.85.90:$NODE_PORT"
juju relate -m cos prometheus-scrape-target-gpu-a prometheus


juju deploy -m cos prometheus-scrape-target-k8s prometheus-scrape-target-gpu-b \
   --channel 1/stable \
   --base ubuntu@20.04 \
   --config job_name=gpu-metrics-gpu-1 \
   --config labels="dns_name:'k8s-cluster-ai-2.maas',kubernetes_node:'k8s-cluster-ai-2'" \
   --config scheme=http \
   --config metrics_path="/metrics" \
   --config targets="10.0.85.102:$NODE_PORT"
juju relate -m cos prometheus-scrape-target-gpu-b prometheus


# Check the targets are there in Prometheus http://10.0.85.200/cos-prometheus-0/targets?search=
echo "Now go to COS Grafana GUI and import the dashboard dcgm-exporter-dashboard.json"
# https://grafana.com/grafana/dashboards/12239-nvidia-dcgm-exporter-dashboard/
```
