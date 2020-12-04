variable cluster_name {
  type        = string
  description = "Name of this cluster, used for naming network and keypair"
  default     = "microk8s"  
}

variable microk8s_channel {
  type        = string
  description = "The installation channel (version) used for microk8s"
  default     = "latest/stable"   
}

variable cluster_token {
  type        = string
  description = "The token used for workers to join cluster"
  default     = "i2CIwKagbV17T9gtFZUkMDYPc7IgniqgYsoMBKyRWYw="
}

variable cluster_token_ttl {
  type        = string
  description = "The token ttl used for workers to join cluster"
  default     = "600"
}

variable start_k8s {
  type        = bool
  description = "If true, will start controller k8s node and workers join"
  default     = false
}

variable number_of_workers {
  type        = number
  description = "Number of worker nodes to add to cluster"
  default     = 2
}

variable controller_name {
  type        = string
  description = ""
  default     = "controller"
}

variable prefix_name_workers {
  type        = string
  description = ""
  default     = "worker"
}

variable ssh_key_pub {
  type        = string
  description = "Path to public key"
  default = ""
}

#variable os_ssh_keypair {
#  type        = string
#  description = "Openstack ssh key that has already been created"
#  default     = ""
#}
variable external_network_id {
  type        = string
  description = "The external network id in openstack"
}

#variable os_network_name {
#  type        = string
#  description = "An existing network in Openstack"
#}

variable floating_ip_pool {
  type        = string
  description = "Pool of floating IPs from which to assign to the controller"
}