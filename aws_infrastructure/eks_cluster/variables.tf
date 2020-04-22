variable "user" {
}

variable "eks_cluster_enabled_logs" {
  type        = list(string)
  description = "A list of enabled cluster logs. Allowed types are api, audit , authenticator , controllerManager,scheduler"
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "gov_wifi_ip" {
}

variable "environment_name" {
}

variable "accountID" {
}

# Subnet

variable "cidr_public"{
}

variable "cidr_public_two"{
}

variable "cidr_private"{
}

variable "cidr_private_two"{
}

variable "cidr_node"{
}

variable "my_computer_ip" {
  
}



