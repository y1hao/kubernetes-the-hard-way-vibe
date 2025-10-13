locals {
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-vpc"
    }
  )
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.tags
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name_prefix}-igw" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name_prefix}-public-rt" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_main_route_table_association" "this" {
  vpc_id         = aws_vpc.this.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "public" {
  for_each = var.public_subnet_cidrs

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone_id    = var.availability_zone_ids[each.key]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-public-${each.key}"
      Role = "Network"
      Tier = "Public"
    }
  )
}

resource "aws_subnet" "private" {
  for_each = var.private_subnet_cidrs

  vpc_id               = aws_vpc.this.id
  cidr_block           = each.value
  availability_zone_id = var.availability_zone_ids[each.key]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-private-${each.key}"
      Role = "Network"
      Tier = "Private"
    }
  )
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = merge(var.tags, { Name = "${var.name_prefix}-nat-eip" })
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[var.nat_gateway_subnet_suffix].id

  tags = merge(var.tags, { Name = "${var.name_prefix}-nat" })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  for_each = var.enable_nat_gateway ? var.private_subnet_cidrs : {}

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name_prefix}-private-rt-${each.key}" })
}

resource "aws_route" "private_internet" {
  for_each = aws_route_table.private

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private" {
  for_each = var.enable_nat_gateway ? aws_subnet.private : {}

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
