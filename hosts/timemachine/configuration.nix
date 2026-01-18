{ config, pkgs, lib, modulesPath, ... }:

let
  auth = import ../../modules/authentik-nginx.nix;
  keys = import ../../config/ssh-keys.nix;
  sslConfig = auth.sslConfig "/etc/ssl/nodeexporter-timemachine-svc.sdko.net";
in {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.loader.grub.enable = true;
  boot.initrd.kernelModules = [ "dm-snapshot" ];

  networking.hostName = "timemachine";

  # Firewall - Samba ports in addition to common SSH
  networking.firewall = {
    allowedTCPPorts = [ 80 443 445 ];
    allowedUDPPorts = [ 137 138 ];
  };

  # TODO: Add https://wiki.sdko.net link here for user management docs
  # TODO: Load hashedPassword from Vault
  users.users = {
    root = {
      hashedPassword = "$6$L3/5BO/M0YfGSKrt$TLbqESpa.ShaCzovng03RjNA97Pk4DIS.p7u0gIvbnGbsQHnsbD2DoNMhz4ePm.3PPbaaK2eiDgxsbjKRuyEG/";
      openssh.authorizedKeys.keys = [ keys.dominic ];
    };

    # Time Machine backup user for Samba authentication
    # Post-install: smbpasswd -a timemachinedominic
    # TODO: Add https://wiki.sdko.net link here for samba setup docs
    timemachinedominic = {
      isNormalUser = true;
      home = "/var/lib/timemachine";
      createHome = false;
      group = "timemachine";
      hashedPassword = "$6$QRnJTSlP//QWvMg2$tAzUCxAxkd44LMcq1YGX2AMjpBYMQaFsUgu3Vo87BRng11HxiW9NdhHW4w9e9MhSjhfSnQbMCcvCuv0M4G7Tg.";
    };
  };

  users.groups.timemachine = {};

  # nginx for node exporter
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
      more_set_headers "Server: SDKO Timemachine Server";
      more_set_headers "Via: 1.1 sws-gateway";
    '';

    virtualHosts."nodeexporter-timemachine-svc.sdko.net" = sslConfig // {
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

  # Avahi for Time Machine discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
    extraServiceFiles = {
      timemachine = ''
        <?xml version="1.0" standalone='no'?>
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h</name>
          <service>
            <type>_smb._tcp</type>
            <port>445</port>
          </service>
          <service>
            <type>_device-info._tcp</type>
            <port>0</port>
            <txt-record>model=TimeCapsule8,119</txt-record>
          </service>
          <service>
            <type>_adisk._tcp</type>
            <port>445</port>
            <txt-record>sys=waMa=0,adVF=0x100</txt-record>
            <txt-record>dk0=adVN=TimeMachine,adVF=0x82</txt-record>
          </service>
        </service-group>
      '';
    };
  };

  # Samba Time Machine
  services.samba = {
    enable = true;
    openFirewall = false;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "Time Machine Backup Server";
        "server role" = "standalone server";
        "security" = "user";
        "map to guest" = "never";
        "guest ok" = "no";
        "socket options" = "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072";
        "use sendfile" = "yes";
        "aio read size" = "16384";
        "aio write size" = "16384";
        "min protocol" = "SMB2";
        "ea support" = "yes";
        "vfs objects" = "fruit streams_xattr";
        "fruit:aapl" = "yes";
        "fruit:metadata" = "stream";
        "fruit:model" = "TimeCapsule8,119";
        "fruit:posix_rename" = "yes";
        "fruit:veto_appledouble" = "no";
        "fruit:nfs_aces" = "no";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "fruit:delete_empty_adfiles" = "yes";
        "logging" = "systemd";
        "log level" = "1";
      };

      "TimeMachine" = {
        "path" = "/var/lib/timemachine";
        "valid users" = "timemachinedominic";
        "writable" = "yes";
        "browseable" = "yes";
        "fruit:time machine" = "yes";
        "fruit:time machine max size" = "600G";
        "create mask" = "0600";
        "directory mask" = "0700";
        "force user" = "timemachinedominic";
        "force group" = "timemachine";
      };
    };
  };

  # Backup directory and SSL certs
  # TODO: Add https://wiki.sdko.net link here for certificate provisioning docs
  systemd.tmpfiles.rules = [
    "d /var/lib/timemachine 0750 timemachinedominic timemachine -"
    "d /etc/ssl/nodeexporter-timemachine-svc.sdko.net 0750 root nginx -"
  ];

  system.stateVersion = "24.11";
}
