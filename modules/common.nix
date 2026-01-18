# Common NixOS module for baremetal servers
#
# This is for NixOS servers
# Docker-based servers are in infra/cluster/
#
# TODO: Add https://wiki.sdko.net link here for server setup docs

{ config, pkgs, lib, ... }:

{
  # Common packages for baremetal servers
  environment.systemPackages = with pkgs; [
    vim
    htop
    ghostty.terminfo
  ];

  # Tailscale on all servers
  services.tailscale.enable = true;

  # UTC timezone
  time.timeZone = "UTC";

  # SSH hardening
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Prometheus node exporter (baremetal - docker servers use containerized exporters)
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    listenAddress = "127.0.0.1";
    enabledCollectors = [
      "systemd"
      "processes"
    ];
  };
}
