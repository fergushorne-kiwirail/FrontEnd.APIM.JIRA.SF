#global_variables.tf
variable "tags" {
  type        = map
  description = "A list of tags associated to all resources"

  default = {
    author        = "terraform"
    owner         = "Integration Team"
    owner_role    = "Integration Team"
    owner_contact = "ICT.Integration@kiwirail.co.nz"
    project       = "Mule Migration"
    application   = "Integration"
    location      = "global"
    environment   = "dv"
  }
}