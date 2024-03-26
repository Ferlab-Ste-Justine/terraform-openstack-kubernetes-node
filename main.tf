locals {
  block_devices = var.image_source.volume_id != "" ? [{
    uuid                  = var.image_source.volume_id
    source_type           = "volume"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = false
  }] : []
  cloudinit_templates = concat([
      {
        filename     = "base.cfg"
        content_type = "text/cloud-config"
        content      = templatefile(
          "${path.module}/files/user_data.yaml.tpl",
          {
            node_name            = var.name
            chrony               = var.chrony
            ssh_host_key_rsa     = var.ssh_host_key_rsa
            ssh_host_key_ecdsa   = var.ssh_host_key_ecdsa
            docker_registry_auth = var.docker_registry_auth
          }
        )
      }
    ],
    var.fluentbit.enabled ? [{
      filename     = "fluent_bit.cfg"
      content_type = "text/cloud-config"
      content      = module.fluentbit_configs.configuration
    }] : []
  )
}

module "fluentbit_configs" {
  source               = "git::https://github.com/Ferlab-Ste-Justine/terraform-cloudinit-templates.git//fluent-bit?ref=v0.13.1"
  install_dependencies = true
  fluentbit = {
    metrics          = var.fluentbit.metrics
    systemd_services = concat(
      var.fluentbit.etcd_tag != "" ? [{
        tag     = var.fluentbit.etcd_tag
        service = "etcd.service"
      }] : [],
      [
        {
          tag     = var.fluentbit.containerd_tag
          service = "containerd.service"
        },
        {
          tag     = var.fluentbit.kubelet_tag
          service = "kubelet.service"
        },
        {
          tag     = var.fluentbit.node_exporter_tag
          service = "node-exporter.service"
        }
      ]
    )
    forward = var.fluentbit.forward
  }
}

data "template_cloudinit_config" "user_data" {
  gzip          = true
  base64_encode = true
  dynamic "part" {
    for_each = local.cloudinit_templates
    content {
      filename     = part.value["filename"]
      content_type = part.value["content_type"]
      content      = part.value["content"]
    }
  }
}

resource "openstack_compute_instance_v2" "k8_node" {
  name      = var.name
  image_id  = var.image_source.image_id != "" ? var.image_source.image_id : null
  flavor_id = var.flavor_id
  key_pair  = var.keypair_name

  user_data = data.template_cloudinit_config.user_data.rendered

  network {
    port = var.network_port.id
  }

  # Dynamically attach the CephFS network port if it is provided
  dynamic "network" {
    for_each = var.cephfs_network_port != null ? [var.cephfs_network_port] : []
    content {
      port = network.value.id
    }
  }
  
  scheduler_hints {
    group = var.server_group.id
  }

  dynamic "block_device" {
    for_each = local.block_devices
    content {
      uuid                  = block_device.value["uuid"]
      source_type           = block_device.value["source_type"]
      boot_index            = block_device.value["boot_index"]
      destination_type      = block_device.value["destination_type"]
      delete_on_termination = block_device.value["delete_on_termination"]
    }
  }


  lifecycle {
    ignore_changes = [
      user_data,
    ]
  }
}