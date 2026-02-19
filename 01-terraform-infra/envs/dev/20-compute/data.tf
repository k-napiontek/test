data "terraform_remote_state" "network" {
    backend = "remote"

    config = {
      organization = "k-napiontek"
      workspaces = {
        name = "3-Tier-Architecture-dev-network"
      }
    }
}