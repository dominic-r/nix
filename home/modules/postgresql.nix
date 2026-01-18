{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    postgresql
    postgresql.dev
    libpq
  ];

  home.sessionVariables = {
    PATH = "${pkgs.postgresql.pg_config}/bin:${pkgs.postgresql}/bin:$PATH";
    LIBRARY_PATH = "${pkgs.postgresql.lib}/lib:$LIBRARY_PATH";
    LD_LIBRARY_PATH = "${pkgs.postgresql.lib}/lib:$LD_LIBRARY_PATH";
    DYLD_LIBRARY_PATH = "${pkgs.postgresql.lib}/lib:$DYLD_LIBRARY_PATH";
    PGCONFIG = "${pkgs.postgresql.pg_config}/bin/pg_config";
  };
}