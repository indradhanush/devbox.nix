# devbox

Reproducible dev box for Ubuntu 24.04.

## Setup

```bash
git clone <repo> devbox && cd devbox && bash bootstrap.sh
```

Re-login after for docker group membership.

## Apply changes

```bash
home-manager switch --flake .#ubuntu
```
