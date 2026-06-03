variable "appliance_name" {
  type    = string
  default = "eurocopilot"
}

variable "version" {
  type    = string
  default = "2.7.0"
}

variable "input_dir" {
  type    = string
  default = "packer/eurocopilot"
}

variable "output_dir" {
  type    = string
  default = "output"
}

variable "headless" {
  type    = bool
  default = true
}
