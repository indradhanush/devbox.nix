{ pkgs, ... }: {
  home.username = "ubuntu";
  home.homeDirectory = "/home/ubuntu";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    asdf-vm
    go
    gnumake
  ];

  programs.home-manager.enable = true;
}
