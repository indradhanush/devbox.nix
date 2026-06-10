{
  pkgs,
  lib,
  config,
  ...
}: let
  # asdf prepends its shims dir to PATH. Both bash and zsh need this or
  # asdf-managed tools (e.g. go) won't resolve once zsh is the login shell.
  asdfInit = ". ${pkgs.asdf-vm}/etc/profile.d/asdf-prepare.sh";
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
    zsh = {
      enable = true;
      initContent = lib.mkAfter ''
        ${asdfInit}
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
