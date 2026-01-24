{ config, pkgs, lib, ... }:

{
  # Nix daemon and settings
  nix = {
    enable = true;
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [ "dominic" ];
      extra-substituters = [ "https://pr-525--authentik-pkg.netlify.app/nix" ];
      extra-trusted-public-keys = [ "authentik-pkg:ZZHUD/9SkS8T1BVVoksE/+QjIo0s3F8/AM/h0J3ckaw=" ];
    };
  };

  # Allow unfree packages globally
  nixpkgs.config.allowUnfree = true;

  # Homebrew configuration
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "zap";
    };

    taps = [
      "bufbuild/buf"
      "hashicorp/tap"
      "steipete/tap"
    ];

    brews = [
      # Development tools
      "buf"
      "cocoapods"
      "git-sizer"
      "kopia"
      "llvm"
      "llvm@20"
      "lld@20"
      "nasm"
      "nim"
      "opencode"
      "pipx"
      "qemu"
      "redis"
      "rsync"
      "tailscale"
      "transmission-cli"
      "wireshark"
      "yamllint"

      # Cross-compilation toolchains
      "i686-elf-grub"
      "x86_64-elf-binutils"
      "x86_64-elf-gcc"
      "x86_64-elf-grub"

      # Hashicorp tools
      "hashicorp/tap/vault"
      "hashicorp/tap/packer"
      "hashicorp/tap/terraform"
    ];

    casks = [
      "1password"
      "1password-cli"
      "claude"
      "steipete/tap/codexbar"
      "ghostty"
      "multipass"
      "ngrok"
      "obs"
      "orbstack"
      "raycast"
      "steam"
      "wireshark-app"
      "tailscale-app"
      "nvidia-geforce-now"
      "opencode-desktop"
    ];
  };

  # macOS system preferences
  system = {
    stateVersion = 5;
    primaryUser = "dominic";

    defaults = {
      dock = {
        autohide = false;
        show-recents = false;
        tilesize = 35;
        largesize = 43;
        magnification = true;
        mineffect = "scale";
        minimize-to-application = true;
        wvous-tl-corner = 2;  # Mission Control
        wvous-br-corner = 14; # Quick Note
      };

      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        FXEnableExtensionChangeWarning = false;
      };

      trackpad = {
        TrackpadCornerSecondaryClick = 2;
      };

      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        AppleICUForce24HourTime = true;
        AppleInterfaceStyle = "Dark";
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
        NSAutomaticCapitalizationEnabled = false;
        "com.apple.swipescrolldirection" = false;
      };
    };

    # Application-specific preferences
    activationScripts.postActivation.text = lib.mkAfter ''
      # Google Chrome: restore last session
      /usr/bin/sudo -u ${config.system.primaryUser} /usr/bin/defaults write com.google.Chrome RestoreOnStartup -int 1
      # Mouse and scroll speed (not supported by nix-darwin defaults)
      /usr/bin/defaults write NSGlobalDomain com.apple.mouse.scaling -float 1.5
      /usr/bin/defaults write NSGlobalDomain com.apple.scrollwheel.scaling -float 0.5
    '';
  };

  users.users.dominic = {
    home = "/Users/dominic";
    shell = pkgs.zsh;
  };
}
