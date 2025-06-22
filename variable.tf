variable "vpc_cidr" {
  type = string
}

variable "subnet" {
  type = map(object({
    subnet_range      = string
    availability_zone = string
    type              = string
  }))
}

variable "natgw_name" {
  type = string
}

variable "route_tables" {
  type = map(
    object({
      cidr_source       = string
      route_destination = string
    })
  )
}