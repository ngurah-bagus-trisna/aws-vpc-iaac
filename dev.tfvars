vpc_cidr = "10.0.0.0/16"
subnet = {
  "public-net" = {
    subnet_range      = "10.0.1.0/24"
    availability_zone = "ap-southeast-1c"
    type              = "public"
  },
  "private-net" = {
    subnet_range      = "10.0.2.0/24"
    availability_zone = "ap-southeast-1c"
    type              = "private"
  }
}

natgw_name = "nb-natgw"

route_tables = {
  "private" = {
    cidr_source       = "0.0.0.0/0"
    route_destination = "nat"
  },
  "public" = {
    cidr_source       = "0.0.0.0/0"
    route_destination = "igw"
  }
}
