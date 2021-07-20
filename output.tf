# Outputs for Terraform

output "master" {
  value = vsphere_virtual_machine.master.*.default_ip_address
}

output "workers" {
  value = vsphere_virtual_machine.worker.*.default_ip_address
}

output "jump" {
  value = vsphere_virtual_machine.jump.default_ip_address
}

output "controllers" {
  value = vsphere_virtual_machine.controller.*.default_ip_address
}

output "backend_lsc" {
  value = vsphere_virtual_machine.backend_lsc.*.default_ip_address
}

output "backend_vmw" {
  value = vsphere_virtual_machine.backend_vmw.*.default_ip_address
}

output "client" {
  value = vsphere_virtual_machine.client.*.default_ip_address
}

output "loadcommand" {
  value = "while true ; do ab -n 50 -c 50 https://100.64.133.53/ ; done"
}

output "destroy" {
  value = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${basename(var.jump.private_key_path)} -t ubuntu@${vsphere_virtual_machine.jump.default_ip_address} 'git clone ${var.ansible.aviPbAbsentUrl} --branch ${var.ansible.aviPbAbsentTag} ; cd ${split("/", var.ansible.aviPbAbsentUrl)[4]} ; ansible-playbook local.yml --extra-vars @${var.controller.aviCredsJsonFile}' ; sleep 5 ; terraform destroy -auto-approve"
  description = "command to destroy the infra"
}

output "ako_install" {
  value = "helm --debug install ako/ako --generate-name --version ${var.vmw.kubernetes.clusters[0].ako.version} -f values.yml --namespace=${var.vmw.kubernetes.clusters[0].ako.namespace} --set avicredentials.username=admin --set avicredentials.password=$avi_password"
}