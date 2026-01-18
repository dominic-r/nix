{ config, pkgs, ... }:

{
  home = {
    username = "dominic";
    homeDirectory = "/Users/dominic";
    stateVersion = "24.05";
  };

  imports = [
    ./modules/git.nix
    ./modules/nix.nix
    ./modules/packages.nix
    ./modules/postgresql.nix
    ./modules/vim.nix
    ./modules/zsh.nix
  ];
}
