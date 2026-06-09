{pkgs, ...}: {
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

  programs.home-manager.enable = true;

  programs.zsh.enable = true;

  programs.bash = {
    enable = true;
    initExtra = ''
      . ${pkgs.asdf-vm}/etc/profile.d/asdf-prepare.sh
    '';
  };
}
