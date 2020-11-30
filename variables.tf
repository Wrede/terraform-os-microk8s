variable "microk8s_channel" {
  type        = string
  description = "The installation channel (version) used for microk8s"
  default     = "latest/stable"   
}

variable "cluster_token" {
  type        = string
  description = "The token used for workers to join cluster"
  default     = ""
}

variable "cluster_token_ttl" {
  type        = string
  description = "The token ttl used for workers to join cluster"
  default     = ""
}

variable "contoller_name" {
  type        = string
  description = ""
  default     = "controller"
}

variable "prefix_name_workers" {
  type        = string
  description = ""
  default     = "worker"
}

variable "os_keypair" {
  type        = string
  description = "Openstack ssh key that has already been created"
  default     = ""
}