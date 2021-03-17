variable "location" {}

variable "prefix" {}

variable "tags" {
  type = map

  default = {
      Environment = "Terraform GS"
      Dept        = "Engineering"
  }
}

variable "sku" {
    default = {
        westus2 = "16.04-LTS"
        eastus2 = "18.04-LTS"
    }
}