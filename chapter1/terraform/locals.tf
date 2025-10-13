locals {
  az_suffixes = [for suffix in keys(var.availability_zone_ids) : suffix]

  base_tags = merge(
    var.default_tags,
    {
      "managed-by" = "terraform"
      "chapter"    = "1"
    }
  )
}
