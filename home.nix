{ pkgs, ... }: {
  home.username = "ubuntu";
  home.homeDirectory = "/home/ubuntu";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    go
    gnumake
  ];

  programs.home-manager.enable = true;
}
