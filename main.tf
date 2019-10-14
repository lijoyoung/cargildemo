# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "lijoDemoVPC" {
  cidr_block = "10.0.0.0/16"
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.lijoDemoVPC.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.lijoDemoVPC.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "pub_subnet_1" {
  vpc_id                  = "${aws_vpc.lijoDemoVPC.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "pub_subnet1"
  }
}

# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb_sg" {
  name        = "elb_sg"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.lijoDemoVPC.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "ssh_http_sg" {
  name        = "ssh_http_sg"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.lijoDemoVPC.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Give a name tag
  tags = {
    Name = "ssh_http_sg"
  }
}

resource "aws_security_group" "flask_sg" {
  name        = "flask_sg"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.lijoDemoVPC.id}"

  # SSH access from anywhere within vpc
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # app access from the VPC
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # app access from the VPC
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Give a name tag
  tags = {
    Name = "flask_sg"
  }
}

resource "aws_elb" "web" {
  name = "web-elb"

  subnets         = ["${aws_subnet.pub_subnet_1.id}"]
  security_groups = ["${aws_security_group.elb_sg.id}"]
  instances       = ["${aws_instance.web.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

# web-server
resource "aws_instance" "web" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "ubuntu"
    host = "${self.public_ip}"
    private_key = "${file(var.private_key_path)}"

    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region
  # we specified
  ami = "${lookup(var.aws_amis, var.aws_region)}"

  # The name of our SSH keypair we created above.
  # key_name = "${aws_key_pair.auth.id}"
  key_name = "${var.key_name}"  

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.ssh_http_sg.id}"]

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = "${aws_subnet.pub_subnet_1.id}"

  # Give a name tag
  tags = {
    Name = "Web-server"
  }

  # We run a remote provisioner on the instance after creating it.
  # In this case, we just install nginx and start it. By default,
  # this should be on port 80
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install nginx",
      "sudo service nginx start",
    ]
  }
}

# DB resources
resource "aws_security_group" "default" {
  name        = "main_rds_sg"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.lijoDemoVPC.id}"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "TCP"
    cidr_blocks = ["${var.cidr_blocks}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.sg_name}"
  }
}

resource "aws_subnet" "pvt_subnet_1" {
  vpc_id            = "${aws_vpc.lijoDemoVPC.id}"
  cidr_block        = "${var.pvt_subnet_1_cidr}"
  availability_zone = "${var.az_1}"

  tags = {
    Name = "pvt_subnet1"
  }
}

resource "aws_subnet" "pvt_subnet_2" {
  vpc_id            = "${aws_vpc.lijoDemoVPC.id}"
  cidr_block        = "${var.pvt_subnet_2_cidr}"
  availability_zone = "${var.az_2}"

  tags = {
    Name = "pvt_subnet2"
  }
}

resource "aws_db_instance" "default" {
  depends_on             = ["aws_security_group.default"]
  identifier             = "${var.identifier}"
  allocated_storage      = "${var.storage}"
  engine                 = "${var.engine}"
  engine_version         = "${lookup(var.engine_version, var.engine)}"
  instance_class         = "${var.instance_class}"
  name                   = "${var.db_name}"
  username               = "${var.username}"
  password               = "${var.password}"
  vpc_security_group_ids = ["${aws_security_group.default.id}"]
  db_subnet_group_name   = "${aws_db_subnet_group.default.id}"
  multi_az = "true"
  skip_final_snapshot = "true"
}

resource "aws_db_subnet_group" "default" {
  name        = "main_subnet_group"
  description = "Our main group of subnets"
  subnet_ids  = ["${aws_subnet.pvt_subnet_1.id}", "${aws_subnet.pvt_subnet_2.id}"]
}

data "template_file" "app-template" {
    template = "${file("app.py.tpl")}"
    vars = {
        host      = "${aws_db_instance.default.address}"
        user      = "${var.username}"
        passwd    = "${var.password}"
        database  = "${var.db_name}"
    }
}
data "template_file" "create-table-template" {
    template = "${file("create_table.py.tpl")}"
    vars = {
        host      = "${aws_db_instance.default.address}"
        user      = "${var.username}"
        passwd    = "${var.password}"
        database  = "${var.db_name}"
    }
}
# app-server
resource "aws_instance" "app" {
  depends_on             = ["aws_db_instance.default"]
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "ubuntu"
    host = "${self.public_ip}"
    private_key = "${file(var.private_key_path)}"

    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region
  # we specified
  ami = "${lookup(var.aws_amis, var.aws_region)}"

  # The name of our SSH keypair we created above.
  # key_name = "${aws_key_pair.auth.id}"
  key_name = "${var.key_name}"  

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.flask_sg.id}"]

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = "${aws_subnet.pub_subnet_1.id}"

  # Give a name tag
  tags = {
    Name = "App-server"
  }

  # We run a remote provisioner on the instance after creating it.
  provisioner "remote-exec" {
    inline = [
      "sudo apt -y update 2>/dev/null",
      "mkdir ~/app",
      "mkdir ~/app/templates"
    ]
  }
  provisioner "file" {
    source      = "wsgi.py"
    destination = "~/app/wsgi.py"
  }
  provisioner "file" {
    source      = "gunicorn_config.py"
    destination = "~/app/gunicorn_config.py"
  }
  provisioner "file" {
    source      = "supervisor.conf"
    destination = "~/app/supervisor.conf"
  }
  provisioner "file" {
    source      = "addmore.html"
    destination = "~/app/templates/addmore.html"
  }
  provisioner "file" {
    source      = "index.html"
    destination = "~/app/templates/index.html"
  }
  provisioner "file" {
    content       = "${data.template_file.app-template.rendered}"
    destination   = "~/app/app.py"
  }
  provisioner "file" {
    content       = "${data.template_file.create-table-template.rendered}"
    destination   = "~/app/create_table.py"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt -y update 2>/dev/null",
      "sudo apt -y install python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools supervisor 2>/dev/null",
      "pip3 install wheel",
      "pip3 install gunicorn flask mysql-connector-python",
      "sudo chmod +x ~/app/create_table.py 2>/dev/null",
      "cd ~/app && python3 create_table.py",
      "sudo mv ~/app/supervisor.conf /etc/supervisor/conf.d/ 2>/dev/null",
      "sudo chown root:root /etc/supervisor/conf.d/supervisor.conf 2>/dev/null",
      "sudo systemctl restart supervisor 2>/dev/null"
    ]
  }
}