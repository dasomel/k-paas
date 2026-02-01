data "openstack_images_image_v2" "ubuntu" {
  name = "ubuntu-20.04"
}

data "openstack_compute_keypair_v2" "cp-keypair" {
  name = "cp-opentofu-keypair"
}

data "openstack_networking_floatingip_v2" "cp-floatingip-master" {
  address = "0.0.0.0"                                                 // Set a floating ip
}
data "openstack_networking_floatingip_v2" "cp-floatingip-worker" {
  address = "0.0.0.0"                                                 // Set a floating ip
}

data "openstack_networking_network_v2" "cp-network" {
  name = "cp-network"
}

data "openstack_networking_subnet_v2" "cp-subnet" {
  name = "cp-subnet"
}

data "openstack_networking_router_v2" "ext_route" {
  name = "ext_route"
}

data "openstack_networking_secgroup_v2" "cp-secgroup" {
  name = "cp-secgroup"
}

resource "openstack_networking_router_interface_v2" "cp-router-interface" {
  router_id = data.openstack_networking_router_v2.ext_route.id
  subnet_id = data.openstack_networking_subnet_v2.cp-subnet.id
}

resource "openstack_compute_instance_v2" "opentofu-master-node" {
  name              = "opentofu-master-node"
  flavor_id         = "m1.large"
  key_pair          = data.openstack_compute_keypair_v2.cp-keypair.id
  security_groups   = [data.openstack_networking_secgroup_v2.cp-secgroup.id]
  availability_zone = "octavia"
  region            = "RegionOne"

  block_device {
    uuid                  = data.openstack_images_image_v2.ubuntu.id
    source_type           = "image"
    volume_size           = 80
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  network {
    uuid = data.openstack_networking_network_v2.cp-network.id
  }
}

resource "openstack_compute_instance_v2" "opentofu-worker-node" {
  name              = "opentofu-worker-node"
  flavor_id         = "m1.large"
  key_pair          = data.openstack_compute_keypair_v2.cp-keypair.id
  security_groups   = [data.openstack_networking_secgroup_v2.cp-secgroup.id]
  availability_zone = "octavia"
  region            = "RegionOne"

  block_device {
    uuid                  = data.openstack_images_image_v2.ubuntu.id
    source_type           = "image"
    volume_size           = 80
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  network {
    uuid = data.openstack_networking_network_v2.cp-network.id
  }
}

resource "openstack_compute_floatingip_associate_v2" "fip_1" {
  floating_ip = data.openstack_networking_floatingip_v2.cp-floatingip-master.address
  instance_id = "${openstack_compute_instance_v2.opentofu-master-node.id}"
  wait_until_associated = true
}

resource "openstack_compute_floatingip_associate_v2" "fip_2" {
  floating_ip = data.openstack_networking_floatingip_v2.cp-floatingip-worker.address
  instance_id = "${openstack_compute_instance_v2.opentofu-worker-node.id}"
  wait_until_associated = true
}