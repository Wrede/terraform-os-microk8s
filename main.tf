provider "openstack" {}

data "user-data-controller" {

}

module "security-groups" {
  source = ""
    
}

module "microk8s-cluster" {
  source                       = "github.com/Wrede/terraform-os-instance/modules/master-slaves"
  number_of_slaves             = 2
  network_name                 = var.os_network_name
  security_groups              = ["default"]
  flavor_name                  = "ssc.small"
  image_name                   = "CoreOS - latest"
  assign_floating_ip_to_master = true
  os_ssh_keypair               = var.os_keypair
  name_master                  = "controller"
}
    
}

resource "null_resource" "start-controller-node" {
  count = "${var.clientnode_count}"

  # trigger this resouce upon 'contoller' instance finishing 
  triggers {
    cluster_instance_ids = module.microk8s-cluster.module.master.this_instance_id
  }

  connection {
    host = element(module.microk8s-cluster.module.master.this_instance_private_ip, 0)
  }
  
  provisioner "remote-exec" {
    # Start controller
    inline = [
      "microk8s add-node --token-ttl ${var.cluster_token_ttl} --token ${var.cluster_token}"
    ]
  }
}

  resource "null_resource" "join_workers" {
    depends_on = [
      null_resource.start_controller_node,
    ]
    count = "${var.clientnode_count}"

    #Run accross all worker nodes
    connection {
      host = element(module.microk8s-cluster.module.slaves.this_instance_private_ip, count.index)
    }
    
    provisioner "remote-exec" {
      # Run service restart on each node in the clutser
      inline = [
        "microk8s join ip-${module.microk8s-cluster.module.master.this_instance_private_ip[0]}:25000/${var.cluster_token}"
      ]
    }
  }
