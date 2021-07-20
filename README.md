# aviVmw

## Goals
Spin up a full VMware/Avi/AKO environment (through Terraform) with:
- vCenter cloud (without NSX-T) including AKO with 3 K8S clusters 
- Linux Cloud integration with SE(s) created automatically

## Prerequisites:
- TF installed in the orchestrator VM
- VM templates configured in V-center:
```
- ubuntu-xenial-16.04-cloudimg-template (which can be configured here: http://cloud-images-archive.ubuntu.com/releases/xenial/release-20180105/ubuntu-16.04-server-cloudimg-amd64.ova)
- ubuntu-bionic-18.04-cloudimg-template
- controller-20.1.3-9085-template
```
- SSH key configured

## Environment:

Terraform Plan has/have been tested against:

### terraform

```
Terraform v0.14.8
+ provider registry.terraform.io/hashicorp/null v3.1.0
+ provider registry.terraform.io/hashicorp/template v2.2.0
+ provider registry.terraform.io/hashicorp/vsphere v2.0.2
```

## variables:
- All the variables are stored in variables.tf
- Credential are configured as environment variables:
```
TF_VAR_vsphere_user=******
TF_VAR_vsphere_server=******
TF_VAR_vsphere_password=******
TF_VAR_avi_password=******
TF_VAR_avi_user=admin
```

## Use the terraform plan to:
- Create a new folder within v-center
- Spin up n Avi Controller
- Spin up n backend VM(s) - count based on the length of var.backend.ipsData - with two interfaces: dhcp for mgmt, static for data traffic
- Spin up n client server(s) - count based on the length of var.client.count - while true ; do ab -n 1000 -c 1000 https://100.64.133.51/ ; done - with two interfaces: dhcp for mgmt, dhcp for data traffic
- Spin up a jump server with ansible and the avisdk installed - userdata to install packages
- Create a yaml variable file - in the jump server
- Call ansible to do the Avi configuration (git clone)

## Run the terraform:
```
cd ~ ; git clone https://github.com/tacobayle/aviVmw ; cd aviVmw ; terraform init ; terraform apply -auto-approve
# the terraform will output the command to destroy the environment.
```

## compatibility matrix
- tag v3.18: vCenter 6.7.0, K8S 1.18.2-00, Avi 20.1.3
- tag v3.24: vCenter 6.7.0, K8S 1.18.2-00, Avi 20.1.6
- tag v3.25: vCenter 6.7.0, K8S 1.21.3-00, Avi 20.1.6