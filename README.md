# About

This terraform module provisions a base vm that can be setup as a worker or master node for a kubernetes cluster.

# Usage

## Input Variables

- **name**: Name to give to the vm.
- **network_port**: Resource of type **openstack_networking_port_v2** to assign to the vm for network connectivity.
- **server_group**: Server group to assign to the node. Should be of type **openstack_compute_servergroup_v2**.
- **image_source**: Source of the image to provision the bastion on. It takes the following keys (only one of the two fields should be used, the other one should be empty):
  - **image_id**: Id of the image to associate with a vm that has local storage
  - **volume_id**: Id of a volume containing the os to associate with the vm
- **flavor_id**: Id of the VM flavor
- **keypair_name**: Name of the keypair that will be used to ssh to the node
- **docker_registry_auth**: Optional docker registry authentication settings to have access to private repositories or to avoid reaching the rate limit for anonymous users.
   - **enabled**: If set to false (the default), no docker config file will be created.
   - **url**: Url of the registry you want to authenticate to.
   - **username**: Username for the authentication.
   - **password**: Password for the authentication.
- **ssh_host_key_rsa**: Rsa host key that will be used by the vm's ssh server. If omitted, a random key will be generated. Expects the following 2 properties:
  - **public**: Public part of the key, in "authorized keys" format.
  - **private**: Private part of the key, in openssh pem format.
- **ssh_host_key_ecdsa**: Ecdsa host key that will be used by the vm's ssh server. If omitted, a random key will be generated. Expects the following 2 properties:
  - **public**: Public part of the key, in "authorized keys" format.
  - **private**: Private part of the key, in openssh pem format.
- **chrony**: Optional chrony configuration for when you need a more fine-grained ntp setup on your vm. It is an object with the following fields:
  - **enabled**: If set to false (the default), chrony will not be installed and the vm ntp settings will be left to default.
  - **servers**: List of ntp servers to sync from with each entry containing two properties, **url** and **options** (see: https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#server)
  - **pools**: A list of ntp server pools to sync from with each entry containing two properties, **url** and **options** (see: https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#pool)
  - **makestep**: An object containing remedial instructions if the clock of the vm is significantly out of sync at startup. It is an object containing two properties, **threshold** and **limit** (see: https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#makestep)
- **fluentbit**: Optional fluent-bit configuration to securely route logs to a fluentd/fluent-bit node using the forward plugin. It has the following keys:
  - **enabled**: If set to false (the default), fluent-bit will not be installed.
  - **containerd_tag**: Tag to assign to logs coming from containerd. Relevant for both masters and workers.
  - **kubelet_tag**: Tag to assign to logs coming from kubelet. Relevant for both masters and workers.
  - **etcd_tag**: Tag to assign to logs coming from etcd. Should be set to empty string on worker nodes to disable as etcd will only be present on master nodes.
  - **node_exporter_tag** Tag to assign to logs coming from the prometheus node exporter
  - **metrics**: Configuration for metrics fluent-bit exposes.
    - **enabled**: Whether to enable the metrics or not
    - **port**: Port to expose the metrics on
  - **forward**: Configuration for the forward plugin that will talk to the external fluentd/fluent-bit node. It has the following keys:
    - **domain**: Ip or domain name of the remote fluentd node.
    - **port**: Port the remote fluentd node listens on
    - **hostname**: Unique hostname identifier for the vm
    - **shared_key**: Secret shared key with the remote fluentd node to authentify the client
    - **ca_cert**: CA certificate that signed the remote fluentd node's server certificate (used to authentify it)
