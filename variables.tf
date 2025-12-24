variable "cidr_block" {
    description = "the CIDR block for the VPC"
    default = "10.0.0.0/16"
}

variable "default_tags" {
    description = "the default tags for the resources"
    default = {
        "terraform" = "true",
        "created_by" = "hieptvh",
        "created_at" = "2025-12-24",
    }
}