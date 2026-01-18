# Authentik forward auth configuration for nginx
#
# TODO: Add https://wiki.sdko.net link here for authentik setup docs
#
# Usage in host config:
#   let
#     auth = import ../../modules/authentik-nginx.nix;
#   in {
#     services.nginx.virtualHosts."example.sdko.net" = auth.sslConfig "/etc/ssl/example.sdko.net" // {
#       locations = auth.locations // { "/" = { ... }; };
#     };
#   }

let
  # NOTE: Apps are pointed to authentik-proxy-cloud-01, not the embedded outpost
  # as one might assume due to the Traefik router rule at:
  # https://git.sdko.net/s.git/tree/infra/cluster/cloud-01/authentik-proxy-cloud-01/docker-compose.yml#n24
  outpostUrl = "https://sso.sdko.net/outpost.goauthentik.io";
in {
  # Nginx extra config for forward auth on a location
  forwardAuthConfig = ''
    auth_request        /outpost.goauthentik.io/auth/nginx;
    error_page          401 = @goauthentik_proxy_signin;
    auth_request_set    $auth_cookie $upstream_http_set_cookie;
    add_header          Set-Cookie $auth_cookie;

    # Translate headers from the outpost back to the upstream
    auth_request_set $authentik_username $upstream_http_x_authentik_username;
    auth_request_set $authentik_groups $upstream_http_x_authentik_groups;
    auth_request_set $authentik_entitlements $upstream_http_x_authentik_entitlements;
    auth_request_set $authentik_email $upstream_http_x_authentik_email;
    auth_request_set $authentik_name $upstream_http_x_authentik_name;
    auth_request_set $authentik_uid $upstream_http_x_authentik_uid;

    proxy_set_header X-authentik-username $authentik_username;
    proxy_set_header X-authentik-groups $authentik_groups;
    proxy_set_header X-authentik-entitlements $authentik_entitlements;
    proxy_set_header X-authentik-email $authentik_email;
    proxy_set_header X-authentik-name $authentik_name;
    proxy_set_header X-authentik-uid $authentik_uid;
  '';

  # Required locations for authentik forward auth
  locations = {
    "/outpost.goauthentik.io" = {
      proxyPass = outpostUrl;
      extraConfig = ''
        proxy_ssl_verify              off;
        proxy_set_header              Host sso.sdko.net;
        proxy_set_header              X-Forwarded-Host $host;
        proxy_set_header              X-Original-URL $scheme://$http_host$request_uri;
        add_header                    Set-Cookie $auth_cookie;
        auth_request_set              $auth_cookie $upstream_http_set_cookie;
        proxy_pass_request_body       off;
        proxy_set_header              Content-Length "";
      '';
    };

    "@goauthentik_proxy_signin" = {
      extraConfig = ''
        internal;
        add_header Set-Cookie $auth_cookie;
        return 302 /outpost.goauthentik.io/start?rd=$scheme://$http_host$request_uri;
      '';
    };
  };

  # SSL config for a virtualHost
  # TODO: Add https://wiki.sdko.net link here for certificate provisioning docs
  sslConfig = certDir: {
    forceSSL = true;
    sslCertificate = "${certDir}/fullchain.cer";
    sslCertificateKey = "${certDir}/key.pem";
    extraConfig = ''
      proxy_buffers 8 16k;
      proxy_buffer_size 32k;
    '';
  };
}
