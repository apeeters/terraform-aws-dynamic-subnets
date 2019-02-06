module "nat_label" {
  source    = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.3.3"
  namespace = "${var.namespace}"
  stage     = "${var.stage}"
  name      = "${var.name}"
  delimiter = "${var.delimiter}"
  tags      = "${var.tags}"
}

locals {
  nat_gateways_count = "${var.nat_gateway_enabled == "true" ? length(var.availability_zones) : 0}"
  nat_instance_count = "${var.nat_instance_id != "" ? length(var.availability_zones) : 0}"
}

resource "aws_eip" "default" {
  count = "${local.nat_gateways_count}"
  vpc   = true
  tags  = "${module.private_label.tags}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_nat_gateway" "default" {
  count         = "${local.nat_gateways_count}"
  allocation_id = "${element(aws_eip.default.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
  tags          = "${module.nat_label.tags}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route" "default" {
  count                  = "${local.nat_gateways_count}"
  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
  nat_gateway_id         = "${element(aws_nat_gateway.default.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  depends_on             = ["aws_route_table.private"]
}

resource "aws_route" "default-nat_instance" {
  count                  = "${local.nat_instance_count}"
  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
  instance_id            = "${var.nat_instance_id}"
  destination_cidr_block = "0.0.0.0/0"
  depends_on             = ["aws_route_table.private"]
}
