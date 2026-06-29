#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s nullglob

LOG_FILE="${HOME}/devbox-bootstrap.log"
exec > >(tee -a "$LOG_FILE") 2>&1

log() { printf '%s %s\n' "$(date -u +%FT%TZ)" "$*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_nix() {
  if command -v nix >/dev/null 2>&1; then
    log "nix already installed, skipping"
    return
  fi
  log "installing nix"
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix |
    sh -s -- install --no-confirm
}

source_nix() {
  local profile="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  if [[ -e "$profile" ]]; then
    # shellcheck source=/dev/null
    . "$profile"
    log "nix profile sourced"
  fi
}

apply_home_manager() {
  local username
  username=$(whoami)
  log "applying home-manager config for ${username}"
  nix --extra-experimental-features 'nix-command flakes' \
    run home-manager/master -- switch -b backup --flake "${SCRIPT_DIR}#${username}"
}

install_docker() {
  if command -v docker >/dev/null 2>&1; then
    log "docker already installed, skipping"
    return
  fi
  log "installing docker"
  sudo apt-get update -qq
  sudo apt-get install -y -qq ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  local arch codename
  arch=$(dpkg --print-architecture)
  # shellcheck disable=SC1091
  codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
  echo "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu ${codename} stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -qq \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin
}

configure_docker_group() {
  local username
  username=$(whoami)
  if groups "$username" | grep -q '\bdocker\b'; then
    log "user already in docker group"
    return
  fi
  log "adding ${username} to docker group"
  sudo usermod -aG docker "$username"
  log "re-login required for docker group membership to take effect"
}

main() {
  log "starting devbox bootstrap"
  install_nix
  source_nix
  apply_home_manager
  install_docker
  configure_docker_group
  log "bootstrap complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
