terraform {
  backend "remote" {
    organization = "amr205"

    workspaces {
      name = "WagtailApache"
    }
  }
}