{ config, pkgs, ... }:

let
  keys = import ../../config/ssh-keys.nix;
in {
  programs.git = {
    enable = true;
    signing = {
      key = keys.gitSigning;
      signByDefault = true;
    };
    settings = {
      user.name = "Dominic R";
      user.email = "dominic@sdko.org";
      credential.helper = "store";
      push.default = "current";
      core.editor = "hx";
      gpg.format = "ssh";
      "gpg \"ssh\"".program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      url."git@github.com:".insteadOf = "https://github.com/";
      url."git@gitlab.com:".insteadOf = "https://gitlab.com/";

      alias.st = "status";
      alias.co = "checkout";
      alias.br = "branch";
    };
  };
}