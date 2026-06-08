{pkgs, ...}: {
  home = {
    username = "ubuntu";
    homeDirectory = "/home/ubuntu";
    stateVersion = "24.11";
    packages = with pkgs; [
      asdf-vm
      gh
      git
      go
      gnumake
    ];
  };

  programs.home-manager.enable = true;
}
