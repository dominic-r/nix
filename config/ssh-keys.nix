# Centralized SSH public keys registry
#
# TODO: Add https://wiki.sdko.net link here for SSH key management docs
#
# Usage:
#   let keys = import ../config/ssh-keys.nix; in {
#     users.users.root.openssh.authorizedKeys.keys = [ keys.dominic ];
#   }

{
  # Primary key for server access
  dominic = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPkyXI1VJ7hDm2AA+ta5yKOTdqjFBfNWKUuhUKuGrMri";

  # Git deploy key (for automated pushes)
  gitDeploy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH7guBCBEx3TZ+2S6m+aKBg9ABSS+0nRvPcu7GjTOwVf";

  # Git commit signing key (1Password)
  gitSigning = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB56gnL8nS1o52KjF4E3JtKJbEBQL+Q+XbWRQtjuew5T";
}
