provider "openstack" {}

resource "openstack_compute_keypair_v2" "keypair" {
  name       = "${var.cluster_name}-keypair"
  public_key = file(var.ssh_key_pub)
}
module "network" {
  source              = "./modules/network"
  name_prefix         = var.cluster_name
  external_network_id = var.external_network_id
}
data template_file "userdata" {
  template = file("${path.module}/templetes/userdata_microk8s.yml")

  vars = {
    microk8s_channel = "latest/stable" #var.microk8s_channel
  }
}

module "ssh-sg" {
  source               = "github.com/Wrede/terraform-os-security-group"
  name                 = "ssh"
  delete_default_rules = false
  ingress_rules        = ["ssh-tcp"]
  #ingress_with_cidr_blocks = [
  #    {
  #      from_port   = 25000
  #      to_port     = 25000
  #      protocol    = "tcp"
  #      description = "microk8s master node"
  #      cidr_blocks = "10.0.0.0/16"   #TODO: add subnet cidr output to network
  #    },
  #]
}

module "controller" {
  source                       = "github.com/Wrede/terraform-os-instance"
  name                         = var.controller_name
  number_of_instances          = 1
  network_name                 = module.network.network_name
  security_groups              = [module.ssh-sg.this_security_group_name[0]] #TODO: fix ouput in terraform-os-security-groups
  flavor_name                  = "ssc.small"
  image_name                   = "Ubuntu 18.04" #TODO: create var
  assign_floating_ip           = true
  floating_ip_pool             = var.floating_ip_pool
  os_ssh_keypair               = openstack_compute_keypair_v2.keypair.name
  
  user_data                    = data.template_file.userdata.rendered
}

module "workers" {
  source                       = "github.com/Wrede/terraform-os-instance"
  name                         = var.prefix_name_workers
  number_of_instances          = var.number_of_workers
  network_name                 = module.network.network_name
  security_groups              = [module.ssh-sg.this_security_group_name[0]]
  flavor_name                  = "ssc.small"
  image_name                   = "Ubuntu 18.04" #TODO: create var
  assign_floating_ip           = false
  os_ssh_keypair               = openstack_compute_keypair_v2.keypair.name
  
  user_data                    = data.template_file.userdata.rendered
}

resource "null_resource" "start-controller-node" {
  # trigger this resouce upon 'contoller' instance finishing
  count      = var.start_k8s ? 1 : 0
  depends_on = [
      module.controller,
    ]
  #triggers = {
  #  cluster_instance_ids = module.microk8s-cluster.master.this_instance_id
  #}

  connection {
    host = element(module.controller.this_instance_private_ip, 0)
  }
  
  provisioner "remote-exec" {
    # Start controller
    inline = [
      "microk8s add-node --token-ttl ${var.cluster_token_ttl} --token ${var.cluster_token}"
    ]
  }
}

  resource "null_resource" "join_workers" {
    count      = var.start_k8s ? var.number_of_workers : 0
    
    depends_on = [
      null_resource.start-controller-node,
    ]
    
    #Run accross all worker nodes
    connection {
      host = element(module.workers.this_instance_private_ip, count.index)
    }
    
    provisioner "remote-exec" {
      # Run service restart on each node in the clutser
      inline = [
        "microk8s join ${module.controller.this_instance_private_ip[0]}:25000/${var.cluster_token}"
      ]
    }
  }
