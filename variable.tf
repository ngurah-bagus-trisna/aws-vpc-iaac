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

variable "db_credentials" {
  type = object({
    username = string
    password = string
  })
  sensitive = true
}

variable "instance" {
  type = map(object({
    ami           = string
    instance_type = string
    subnet        = string
  }))
}
