{ config, pkgs, lib, modulesPath, ... }:

let
  hooks = ./hooks;
  auth = import ../../modules/authentik-nginx.nix;
  keys = import ../../config/ssh-keys.nix;
  sslConfig = auth.sslConfig "/etc/ssl/git.sdko.net";
in {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.loader.grub.enable = true;
  boot.initrd.kernelModules = [ "dm-snapshot" ];

  environment.systemPackages = with pkgs; [
    ruby
  ];

  networking.hostName = "cgit";
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # TODO: Add https://wiki.sdko.net link here for user management docs
  # TODO: Load hashedPassword from Vault
  users.users = {
    root = {
      hashedPassword = "$6$L3/5BO/M0YfGSKrt$TLbqESpa.ShaCzovng03RjNA97Pk4DIS.p7u0gIvbnGbsQHnsbD2DoNMhz4ePm.3PPbaaK2eiDgxsbjKRuyEG/";
      openssh.authorizedKeys.keys = [ keys.dominic ];
    };

    git = {
      isNormalUser = true;
      home = "/home/git";
      shell = "${pkgs.git}/bin/git-shell";
      openssh.authorizedKeys.keys = [ keys.dominic keys.gitDeploy ];
    };
  };

  # cgit configuration
  services.cgit.main = {
    enable = true;
    nginx.virtualHost = "git.sdko.net";
    scanPath = "/repos";
    gitHttpBackend.checkExportOkFiles = false;
    settings = {
      root-title = "Git Repositories";
      root-desc = "Public git repositories";
      enable-index-owner = 0;
      enable-commit-graph = 1;
      enable-log-filecount = 1;
      enable-log-linecount = 1;
      max-repo-count = 50;
      cache-size = 1000;
      snapshots = "tar.gz tar.xz zip";
      clone-url = "https://git.sdko.net/$CGIT_REPO_URL git@git.sdko.net:repos/$CGIT_REPO_URL";
      source-filter = "${pkgs.cgit}/lib/cgit/filters/syntax-highlighting.py";
      about-filter = "${pkgs.cgit}/lib/cgit/filters/about-formatting.sh";
    };
  };

  # nginx
  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = false;
    serverTokens = false;
    package = pkgs.nginxMainline.override {
      modules = [ pkgs.nginxModules.moreheaders ];
    };

    commonHttpConfig = ''
      more_set_headers "Server: SDKO Git Server";
      more_set_headers "Via: 1.1 sws-gateway";

      map $http_upgrade $connection_upgrade_keepalive {
        default upgrade;
        ""      "";
      }
    '';

    virtualHosts."git.sdko.net" = sslConfig // {
      locations = auth.locations // {
        "/" = {
          extraConfig = auth.forwardAuthConfig + ''
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            # WebSocket support
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade_keepalive;
          '';
        };
      };
    };

    virtualHosts."nodeexporter-git-svc.sdko.net" = sslConfig // {
      locations = auth.locations // {
        "/" = {
          proxyPass = "http://127.0.0.1:9100";
          extraConfig = auth.forwardAuthConfig + ''
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };
    };
  };

  # Create directory structure
  # /home/git/repos/{thing} - actual repos owned by git user
  # /repos/{repo} - symlinks for cgit to scan
  # TODO: Add https://wiki.sdko.net link here for certificate provisioning docs
  systemd.tmpfiles.rules = [
    "d /home/git 0755 git users -"
    "d /home/git/repos 0755 git users -"
    "d /home/git/.ssh 0700 git users -"
    "d /repos 0755 root root -"
    "d /etc/ssl/git.sdko.net 0750 root nginx -"
  ];

  # Initialize default repos if they don't exist
  systemd.services.init-git-repos = {
    description = "Initialize default git repositories";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      init_repo() {
        local name=$1
        local desc=$2
        if [ ! -d /home/git/repos/$name.git ]; then
          ${pkgs.git}/bin/git init --bare --initial-branch=master /home/git/repos/$name.git
          chown -R git:users /home/git/repos/$name.git
        fi
        echo "$desc" > /home/git/repos/$name.git/description
        if [ ! -L /repos/$name.git ]; then
          ln -sf /home/git/repos/$name.git /repos/$name.git
        fi
      }

      install_hooks() {
        local name=$1
        local skip_prereceive=$2
        mkdir -p /home/git/repos/$name.git/hooks

        # Pre-receive: enforce merge commits on master
        if [ "$skip_prereceive" != "true" ]; then
          cp ${hooks}/pre-receive-merge-only /home/git/repos/$name.git/hooks/pre-receive
          chmod +x /home/git/repos/$name.git/hooks/pre-receive
        else
          rm -f /home/git/repos/$name.git/hooks/pre-receive
        fi

        # Post-receive: mirror to Codeberg
        cp ${hooks}/post-receive-mirror /home/git/repos/$name.git/hooks/post-receive
        chmod +x /home/git/repos/$name.git/hooks/post-receive

        chown -R git:users /home/git/repos/$name.git/hooks
      }

      init_repo "s" "Monorepo."
      init_repo "s-test" "Monorepo testing."
      init_repo "hl-bootstrap-automatic" "Homelab bootstrap (auto-synced from monorepo)."
      init_repo "m" "Mom's project."
      init_repo "playground" "Playing around with random shit."
      init_repo "prog-2025-2026-tp" "Programming class 2025-2026 ~ Travaux Pratiques"
      init_repo "prog-2025-2026-labo" "Programming class 2025-2026 ~ Laboratoires"
      init_repo "schcc" "School project."

      install_hooks "s"
      install_hooks "s-test"
      install_hooks "hl-bootstrap-automatic" true
      install_hooks "m"
      install_hooks "playground" true
      install_hooks "prog-2025-2026-tp" true
      install_hooks "prog-2025-2026-labo" true
      install_hooks "schcc"
    '';
  };

  # Fix permissions on every boot/switch
  systemd.services.fix-git-perms = {
    description = "Fix git repository permissions for cgit";
    wantedBy = [ "multi-user.target" ];
    after = [ "init-git-repos.service" ];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      chmod 755 /home/git
      chmod -R o+rX /home/git/repos 2>/dev/null || true
    '';
  };

  system.stateVersion = "24.11";
}
