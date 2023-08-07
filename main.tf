data "template_cloudinit_config" "user_data" {
  gzip = false
  base64_encode = false
  part {
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/files/user_data.yaml.tpl", 
      {
        node_name = var.name
        chrony = var.chrony
        ssh_host_key_rsa = var.ssh_host_key_rsa
        ssh_host_key_ecdsa = var.ssh_host_key_ecdsa
        docker_registry_auth = var.docker_registry_auth
      }
    )
  }
}

resource "openstack_compute_instance_v2" "k8_node" {
  name            = var.name
  flavor_id       = var.flavor_id
  key_pair        = var.keypair_name

  user_data = data.template_cloudinit_config.user_data.rendered
  
  network {
    port = var.network_port.id
  }

  scheduler_hints {
    group = var.server_group.id
  }

  dynamic "block_device" {
    for_each = var.boot_from_volume ? [1] : []
    content {
      uuid                  = var.volume_id
      source_type           = "volume"
      destination_type      = "volume"
      boot_index            = 0
      delete_on_termination = false
    }
  }

  image_id = var.boot_from_volume ? null : var.image_id

  lifecycle {
    ignore_changes = [
      user_data,
    ]
  }
}