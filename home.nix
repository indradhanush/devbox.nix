{
  pkgs,
  lib,
  config,
  ...
}: let
  # asdf prepends its shims dir to PATH. Both bash and zsh need this or
  # asdf-managed tools (e.g. go) won't resolve once zsh is the login shell.
  asdfInit = ". ${pkgs.asdf-vm}/etc/profile.d/asdf-prepare.sh";

  # clusterctl pinned to v1.4.4 to match the CAPI version the byoh provider is
  # exercised against (test/e2e/config/provider.yaml). nixpkgs ships only the
  # latest clusterctl, which would `clusterctl init` a newer, likely-
  # incompatible CAPI. Static Go binary, so no autoPatchelfHook needed.
  clusterctl = pkgs.stdenv.mkDerivation rec {
    pname = "clusterctl";
    version = "1.4.4";
    src = pkgs.fetchurl {
      url = "https://github.com/kubernetes-sigs/cluster-api/releases/download/v${version}/clusterctl-linux-amd64";
      hash = "sha256-DouHjTB8EcZ6uCM7wvb6HxPtl4lBIPhuaWXtbq/OU0U=";
    };
    dontUnpack = true;
    installPhase = "install -Dm755 $src $out/bin/clusterctl";
  };
in {
  home = {
    username = "ubuntu";
    homeDirectory = "/home/ubuntu";
    stateVersion = "24.11";
    packages = with pkgs; [
      asdf-vm
      gh
      git
      gcc
      just
      gnumake
      tree
      watchexec
      # byoh single-box dev loop (Set A): kind mgmt cluster, kubectl, tilt.
      # clusterctl is the pinned v1.4.4 let-binding above (shadows pkgs.clusterctl).
      kind
      kubectl
      tilt
      clusterctl
    ];
  };

  # Registers the nix-managed zsh in /etc/shells and sets it as the login
  # shell so SSH sessions use zsh. Runs on every home-manager switch, which
  # covers both fresh bootstraps and incremental syncs.
  home.activation.registerZshShell = lib.hm.dag.entryAfter ["writeBoundary"] ''
    zsh_path="${config.home.profileDirectory}/bin/zsh"
    if ! grep -qF "$zsh_path" /etc/shells 2>/dev/null; then
      $DRY_RUN_CMD /usr/bin/sudo /bin/sh -c "echo '$zsh_path' >> /etc/shells"
    fi
    current_shell=$(/usr/bin/getent passwd "$USER" | cut -d: -f7)
    if [[ "$current_shell" != "$zsh_path" ]]; then
      $DRY_RUN_CMD /usr/bin/sudo /usr/bin/chsh -s "$zsh_path" "$USER"
    fi
  '';

  programs = {
    home-manager.enable = true;
    # Installs zoxide and injects the `z` jump function into zsh/bash.
    zoxide.enable = true;
    tmux.enable = true;
    zsh = {
      enable = true;
      # .zshenv is sourced for all zsh invocations (interactive, login, and
      # non-interactive SSH). PATH must be set here so `ssh host "cmd"` works.
      # asdfInit also has to live here (not just initContent/.zshrc) so
      # asdf-managed tools like `go` resolve over non-interactive SSH too.
      envExtra = ''
        export PATH="$HOME/.nix-profile/bin:$PATH"
        ${asdfInit}
      '';
      initContent = lib.mkAfter ''
        # %m = hostname, %~ = cwd (~-abbreviated), %# = # for root else %.
        PROMPT='%m %~ %# '
      '';
    };
    bash = {
      enable = true;
      initExtra = ''
        ${asdfInit}
      '';
    };
  };
}
