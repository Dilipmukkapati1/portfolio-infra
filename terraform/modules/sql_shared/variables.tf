variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "server_name" {
  type = string
}

variable "database_names" {
  type = list(string)
}

variable "admin_login" {
  type    = string
  default = "ppmadmin"
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "max_size_gb" {
  type    = number
  default = 32
}

variable "sku_name" {
  type    = string
  default = "GP_S_Gen5_2"
}

variable "min_capacity" {
  type    = number
  default = 0.5
}

variable "auto_pause_delay_in_minutes" {
  type    = number
  default = 60
}

variable "use_free_offer" {
  type    = bool
  default = true
}

variable "free_limit_exhaustion_behavior" {
  type    = string
  default = "AutoPause"
}

variable "allow_current_client_ip" {
  type        = bool
  description = "At apply time, resolve this machine's public IP (api.ipify.org) and add a SQL firewall rule"
  default     = false
}

variable "additional_client_ips" {
  type        = list(string)
  description = "Extra IPv4 addresses allowed to connect (e.g. home office, VPN exit)"
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
