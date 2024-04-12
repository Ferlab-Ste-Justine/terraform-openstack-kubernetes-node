variable "name" {
  description = "Name of the vm"
  type        = string
}

variable "network_ports" {
  type = list(object({
    id = string
  }))
  description = "List of network ports for the instance"
}

variable "server_group" {
  description = "Server group to assign to the node. Should be of type openstack_compute_servergroup_v2"
  type        = any
}

variable "image_source" {
  description = "Source of the vm's image"
  type = object({
    image_id  = string
    volume_id = string
  })

  validation {
    condition     = (var.image_source.image_id != "" && var.image_source.volume_id == "") || (var.image_source.image_id == "" && var.image_source.volume_id != "")
    error_message = "You must provide either an image_id or a volume_id, but not both."
  }
}

variable "flavor_id" {
  description = "ID of the VM flavor"
  type        = string
}

variable "keypair_name" {
  description = "Name of the keypair that will be used by admins to ssh to the node"
  type        = string
}

variable "ssh_host_key_rsa" {
  type = object({
    public  = string
    private = string
  })
  default = {
    public  = ""
    private = ""
  }
}

variable "ssh_host_key_ecdsa" {
  type = object({
    public  = string
    private = string
  })
  default = {
    public  = ""
    private = ""
  }
}

variable "chrony" {
  description = "Chrony configuration for ntp. If enabled, chrony is installed and configured, else the default image ntp settings are kept"
  type = object({
    enabled = bool,
    //https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#server
    servers = list(object({
      url     = string,
      options = list(string)
    })),
    //https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#pool
    pools = list(object({
      url     = string,
      options = list(string)
    })),
    //https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#makestep
    makestep = object({
      threshold = number,
      limit     = number
    })
  })
  default = {
    enabled = false
    servers = []
    pools   = []
    makestep = {
      threshold = 0,
      limit     = 0
    }
  }
}

variable "docker_registry_auth" {
  description = "Docker registry authentication settings"
  type = object({
    enabled  = bool,
    url      = string,
    username = string,
    password = string
  })
  default = {
    enabled  = false
    url      = "https://index.docker.io/v1/"
    username = ""
    password = ""
  }
}

variable "fluentbit" {
  description = "Fluent-bit configuration"
  sensitive = true
  type = object({
    enabled = bool
    containerd_tag = string
    kubelet_tag = string
    etcd_tag = string
    node_exporter_tag = string
    metrics = object({
      enabled = bool
      port    = number
    })
    forward = object({
      domain = string
      port = number
      hostname = string
      shared_key = string
      ca_cert = string
    })
  })
  default = {
    enabled = false
    containerd_tag = ""
    kubelet_tag = ""
    etcd_tag = ""
    node_exporter_tag = ""
    metrics = {
      enabled = false
      port = 0
    }
    forward = {
      domain = ""
      port = 0
      hostname = ""
      shared_key = ""
      ca_cert = ""
    }
  }
}

