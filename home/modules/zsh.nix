{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;

    # Oh My Zsh configuration
    oh-my-zsh = {
      enable = true;
      theme = "refined";
      plugins = [
        "git"
        "docker"
        "kubectl"
        "aws"
        "sudo"
      ];
    };

    # Shell aliases
    shellAliases = {
      nano = "hx";
      htop = "btop";
      cp = "cp -i";
      mv = "mv -i";
      rm = "rm -i";
      mkdir = "mkdir -p";
      k = "kubectl";
      d = "docker";
      m = "make";
      o = "opencode";
      g = "git";
      t = "task";
      c = "claude";
      b = "bun";
      u = "uv";
      st = "~/Developer/s/apps/st/bin/st";
      flushdns = "sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder";
      aktest = "uv run python -m coverage run manage.py test --keepdb --randomly-seed 89834583";
      ak-run = "sudo lsof -ti:8000,9000,9443 | xargs sudo kill -9 2>/dev/null || true && tmux new-session -d -s ak-dev \\; send-keys 'make gen-build && make gen-client-ts && make web-watch' C-m \\; split-window -h \\; send-keys 'sleep 40 && make run-server' C-m \\; select-pane -L \\; split-window -v \\; send-keys 'sleep 45 && make run-worker' C-m \\; select-pane -U \\; attach-session -t ak-dev";
      ak-kill = "tmux kill-session -t ak-dev";
    };

    # Additional shell initialization
    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # Managed by Nix Home Manager
        # Source: ~/Developer/s/nix2/home/modules/zsh.nix
        # Manual edits will be overwritten
      '')
      ''

      # Acme.sh environment
      [[ -f "$HOME/.acme.sh/acme.sh.env" ]] && source "$HOME/.acme.sh/acme.sh.env"

      # Zoxide initialization
      eval "$(zoxide init zsh)"

      # Nix daemon
      source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

      # Home Manager session vars
      # nix-darwin installs Home Manager's profile under /etc/profiles/per-user/$USER
      if [[ -f "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh" ]]; then
        source "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
      elif [[ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]]; then
        source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
      fi

      # Prefer Nix profile binaries over Homebrew (e.g. `node`).
      typeset -U path PATH
      path=(/etc/profiles/per-user/$USER/bin $HOME/.nix-profile/bin $path)
      rehash

      # Fastfetch on interactive shells
      if [[ $- == *i* ]]; then
          fastfetch
      fi

      # Auto-activate venv when entering configured directories
      if [[ $- == *i* ]]; then
        autoload -U add-zsh-hook

        # Directories with uv venvs to auto-activate
        typeset -a _SDKO_VENV_DIRS
        _SDKO_VENV_DIRS=(
          "$HOME/Developer/goauthentik/authentik"
          "$HOME/Developer/memory"
        )

        _sdko_auto_venv() {
          local target venv activate

          # Check if we're in any of the configured directories
          for target in "''${_SDKO_VENV_DIRS[@]}"; do
            venv="$target/.venv"
            activate="$venv/bin/activate"

            if [[ "$PWD" == "$target" || "$PWD" == "$target/"* ]]; then
              if [[ -f "$activate" && "$VIRTUAL_ENV" != "$venv" ]]; then
                source "$activate"
                export _SDKO_AUTO_VENV_ACTIVE="$venv"
              fi
              return
            fi
          done

          # Not in any target directory - deactivate if we auto-activated
          if [[ -n "$_SDKO_AUTO_VENV_ACTIVE" && "$VIRTUAL_ENV" == "$_SDKO_AUTO_VENV_ACTIVE" ]]; then
            if typeset -f deactivate >/dev/null 2>&1; then
              deactivate
            fi
            unset _SDKO_AUTO_VENV_ACTIVE
          fi
        }

        add-zsh-hook -d chpwd _sdko_auto_venv 2>/dev/null || true
        add-zsh-hook chpwd _sdko_auto_venv
        _sdko_auto_venv

        # Auto-set xmlsec environment for authentik development
        _sdko_authentik_xmlsec() {
          local authentik_dir="$HOME/Developer/goauthentik/authentik"

          if [[ "$PWD" == "$authentik_dir" || "$PWD" == "$authentik_dir/"* ]]; then
            if [[ -z "$_SDKO_XMLSEC_ACTIVE" ]]; then
              # Find dev pkgconfig paths in nix store
              local xmlsec_pc=$(echo /nix/store/*-xmlsec-*-dev/lib/pkgconfig(N[1]))
              local libxml2_pc=$(echo /nix/store/*-libxml2-*-dev/lib/pkgconfig(N[1]))
              local libxslt_pc=$(echo /nix/store/*-libxslt-*-dev/lib/pkgconfig(N[1]))
              if [[ -n "$xmlsec_pc" && -d "$xmlsec_pc" ]]; then
                export PKG_CONFIG_PATH="$xmlsec_pc:$libxml2_pc:$libxslt_pc:$PKG_CONFIG_PATH"
                export LDFLAGS="$LDFLAGS $(pkg-config --libs xmlsec1-openssl)"
                export CPPFLAGS="$CPPFLAGS $(pkg-config --cflags xmlsec1-openssl)"
                export _SDKO_XMLSEC_ACTIVE=1
              fi
            fi
          else
            if [[ -n "$_SDKO_XMLSEC_ACTIVE" ]]; then
              unset _SDKO_XMLSEC_ACTIVE
              # Reset to defaults from sessionVariables
              export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"
              export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
              # Remove xmlsec from PKG_CONFIG_PATH
              export PKG_CONFIG_PATH="''${PKG_CONFIG_PATH%%:*}"
            fi
          fi
        }

        add-zsh-hook -d chpwd _sdko_authentik_xmlsec 2>/dev/null || true
        add-zsh-hook chpwd _sdko_authentik_xmlsec
        _sdko_authentik_xmlsec
      fi
      ''
    ];
  };

  # Environment variables
  home.sessionVariables = {
    COMPOSE_BAKE = "true";
    GO_PATH = "${config.home.homeDirectory}/go";
    KUBECONFIG = "${config.home.homeDirectory}/.kube/config.k3s";
    BUN_INSTALL = "${config.home.homeDirectory}/.bun";
    BUN_FEATURE_FLAG_DISABLE_IPV6 = "1";
    NODE_OPTIONS = "--no-experimental-webstorage";
    SDKROOT = "$(xcrun --sdk macosx --show-sdk-path)";
    CPPFLAGS = "-I/opt/homebrew/opt/llvm/include";
    LDFLAGS = "-L/opt/homebrew/opt/llvm/lib";
  };

  # PATH management
  home.sessionPath = [
    "/etc/profiles/per-user/${config.home.username}/bin"
    "${config.home.homeDirectory}/.nix-profile/bin"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/go/bin"
    "/opt/homebrew/opt/ruby/bin"
    "/opt/homebrew/lib/ruby/gems/3.4.0/bin"
    "/opt/homebrew/opt/llvm/bin"
    "/opt/homebrew/bin"
  ];

  # Drift detection; completly useless at this time since the zshrc and zshenv are created as read-only
  home.activation.checkZshDrift = config.lib.dag.entryBefore ["writeBoundary"] ''
    ZSHRC="$HOME/.zshrc"
    CHECKSUM_FILE="$HOME/.zshrc.nix-checksum"

    # If .zshrc exists and we have a previous checksum
    if [ -f "$ZSHRC" ] && [ -f "$CHECKSUM_FILE" ]; then
      CURRENT_CHECKSUM=$(${pkgs.coreutils}/bin/sha256sum "$ZSHRC" | cut -d' ' -f1)
      EXPECTED_CHECKSUM=$(cat "$CHECKSUM_FILE")

      if [ "$CURRENT_CHECKSUM" != "$EXPECTED_CHECKSUM" ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "ERROR: Drift detected in $ZSHRC"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "The file has been modified outside of Nix."
        echo ""
        echo "Expected checksum: $EXPECTED_CHECKSUM"
        echo "Current checksum:  $CURRENT_CHECKSUM"
        echo ""
        echo "To fix this, either:"
        echo "  1. Revert manual changes and reapply"
        echo "  2. Add your changes to ~/Developer/s/nix2/home/modules/zsh.nix"
        echo ""
        exit 1
      fi
    fi
  '';

  # Save checksum after writing files for next drift check
  home.activation.saveZshChecksum = config.lib.dag.entryAfter ["writeBoundary"] ''
    if [ -f "$HOME/.zshrc" ]; then
      ${pkgs.coreutils}/bin/sha256sum "$HOME/.zshrc" | cut -d' ' -f1 > "$HOME/.zshrc.nix-checksum"
    fi
  '';

  # Activation script to remind user to reload shell
  home.activation.zshReloadReminder = config.lib.dag.entryAfter ["writeBoundary"] ''
    echo "INFO: Don't forget to reload your shell: source ~/.zshrc"
  '';
}
