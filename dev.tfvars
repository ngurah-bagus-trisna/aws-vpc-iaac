vpc_cidr = "10.0.0.0/16"
subnet = {
  "public-net" = {
    subnet_range      = "10.0.1.0/24"
    availability_zone = "ap-southeast-1a"
    type              = "public"
  },
  "private-net-1" = {
    subnet_range      = "10.0.2.0/24"
    availability_zone = "ap-southeast-1c"
    type              = "private"
  },
  "private-net-2" = {
    subnet_range      = "10.0.3.0/24"
    availability_zone = "ap-southeast-1b"
    type              = "private"
  },
  "private-net-3" = {
    subnet_range      = "10.0.4.0/24"
    availability_zone = "ap-southeast-1a"
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

instance = {
  "web-private" = {
    ami           = "ami-02c7683e4ca3ebf58"
    instance_type = "t2.micro"
    subnet        = "private-net-1"
  },
  "web-public" = {
    ami           = "ami-02c7683e4ca3ebf58"
    instance_type = "t2.micro"
    subnet        = "public-net"
  }
}