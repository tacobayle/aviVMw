data "template_file" "worker_userdata" {
  count = length(var.vmw.kubernetes.clusters) * var.vmw.kubernetes.workers.count
  template = file("${path.module}/userdata/worker.userdata")
  vars = {
    netplanFile  = var.vmw.kubernetes.clusters[floor(count.index / var.vmw.kubernetes.workers.count)].worker.netplanFile
    pubkey       = file(var.jump.public_key_path)
    dockerVersion = var.vmw.kubernetes.clusters[floor(count.index / var.vmw.kubernetes.workers.count)].docker.version
    username = var.vmw.kubernetes.clusters[floor(count.index / var.vmw.kubernetes.workers.count)].username
    docker_registry_username = var.docker_registry_username
    docker_registry_password = var.docker_registry_password
    cni = var.vmw.kubernetes.clusters[floor(count.index / var.vmw.kubernetes.workers.count)].cni.name
    cniUrl = var.vmw.kubernetes.clusters[floor(count.index / var.vmw.kubernetes.workers.count)].cni.url
    akoVersion = var.vmw.kubernetes.clusters[floor(count.index / var.vmw.kubernetes.workers.count)].ako.version
    argocd_status = var.vmw.kubernetes.argocd.status
    argocd_manifest_url = var.vmw.kubernetes.argocd.manifest_url
  }
}

data "vsphere_virtual_machine" "worker" {
  count = length(var.vmw.kubernetes.clusters) * var.vmw.kubernetes.workers.count
  name          = var.vmw.kubernetes.clusters[floor(count.index / var.vmw.kubernetes.workers.count)].worker.template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "worker" {
  count = length(var.vmw.kubernetes.clusters) * var.vmw.kubernetes.workers.count
  name             = "${var.vmw.kubernetes.clusters[floor(count.index / var.vmw.kubernetes.workers.count)].name}-worker-${count.index - floor(count.index / var.vmw.kubernetes.workers.count) * var.vmw.kubernetes.workers.count + 1 }"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folder.path

  network_interface {
    network_id = data.vsphere_network.networkMgt.id
  }

  network_interface {
    network_id = data.vsphere_network.networkWorker[count.index].id
  }

  num_cpus = var.vmw.kubernetes.clusters[floor(count.index / var.vmw.kubernetes.workers.count)].worker.cpu
  memory = var.vmw.kubernetes.clusters[floor(count.index / var.vmw.kubernetes.workers.count)].worker.memory
  #wait_for_guest_net_timeout = var.worker["wait_for_guest_net_timeout"]
  wait_for_guest_net_routable = var.vmw.kubernetes.clusters[floor(count.index / var.vmw.kubernetes.workers.count)].worker.wait_for_guest_net_routable
  guest_id = data.vsphere_virtual_machine.worker[count.index].guest_id
  scsi_type = data.vsphere_virtual_machine.worker[count.index].scsi_type
  scsi_bus_sharing = data.vsphere_virtual_machine.worker[count.index].scsi_bus_sharing
  scsi_controller_count = data.vsphere_virtual_machine.worker[count.index].scsi_controller_scan_count

  disk {
    size             = var.vmw.kubernetes.clusters[floor(count.index / var.vmw.kubernetes.workers.count)].worker.disk
    label            = "${var.vmw.kubernetes.clusters[floor(count.index / var.vmw.kubernetes.workers.count)].name}-worker-${count.index}"
    eagerly_scrub    = data.vsphere_virtual_machine.worker[count.index].disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.worker[count.index].disks.0.thin_provisioned
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.worker[count.index].id
  }

  vapp {
    properties = {
      hostname    = "${var.vmw.kubernetes.clusters[floor(count.index / var.vmw.kubernetes.workers.count)].name}-worker-${count.index - floor(count.index / var.vmw.kubernetes.workers.count) * var.vmw.kubernetes.workers.count + 1 }"
      public-keys = file(var.jump.public_key_path)
      user-data   = base64encode(data.template_file.worker_userdata[count.index].rendered)
    }
  }

  connection {
    host        = self.default_ip_address
    type        = "ssh"
    agent       = false
    user        = var.vmw.kubernetes.clusters[floor(count.index / var.vmw.kubernetes.workers.count)].username
    private_key = file(var.jump.private_key_path)
  }

  provisioner "remote-exec" {
    inline      = [
      "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
    ]
  }
}
