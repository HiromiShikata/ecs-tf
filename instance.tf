resource "aws_ecs_cluster" "tmp-cluster" {
	name = "tmp-cluster"
}
resource "aws_launch_configuration" "tmp-instance" {
	name_prefix = "tmp-ecs-instance-"
	instance_type = "t2.micro"
	image_id = "ami-68ef940e"
}

resource "aws_ecs_task_definition" "frontend" {
	family = "frontend"
	container_definitions = <<EOF
[{
	"name": "frontend",
	"image": "nginx",
	"cpu": 1024,
	"memory": 768,
	"essential": true,
	"portMappings": [{"containerPort": 80, "hostPort": 80}]
}]
EOF
}
resource "aws_vpc" "vpc" {
	cidr_block = "10.0.0.0/16"
	instance_tenancy = "default"
	enable_dns_support = "true"
	enable_dns_hostnames = "false"
}

resource "aws_internet_gateway" "gateway" {
	vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_route_table" "route_table" {
	vpc_id = "${aws_vpc.vpc.id}"
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.gateway.id}"
	}
}

resource "aws_subnet" "subnet" {
	vpc_id = "${aws_vpc.vpc.id}"
	cidr_block = "10.0.2.0/24"
	availability_zone = "ap-northeast-1a"
}


resource "aws_autoscaling_group" "tmp-cluster-instances" {
	name = "cluster-instances"
	availability_zones = ["ap-northeast-1a"]
	min_size = 2 
	max_size = 3
	vpc_zone_identifier = ["${aws_subnet.subnet.id}"]
	launch_configuration = "${aws_launch_configuration.tmp-instance.name}"
}


resource "aws_ecs_service" "frontend" {
	name = "frontend"
	cluster = "${aws_ecs_cluster.tmp-cluster.id}"
	task_definition = "${aws_ecs_task_definition.frontend.arn}"
	desired_count = 2
	load_balancer {
		elb_name = "${aws_elb.frontend.id}"
		container_name = "frontend"
		container_port = 80
	}
}



resource "aws_elb" "frontend" {
	name = "frontend"
	subnets = ["${aws_subnet.subnet.id}"]
	listener {
		lb_port = 80
		lb_protocol = "http"
		instance_port = 80
		instance_protocol = "http"
	}
}

