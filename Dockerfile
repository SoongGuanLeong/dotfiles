# Clean-room Docker test for dotfiles Home Manager activation.
#
# Build context: repository root.
# Build: docker build -t dotfiles-test .
# Run:   docker run dotfiles-test
#
# Uses upstream Nix installer with --no-daemon (single-user).
# Docker containers lack systemd, so Determinate daemon mode not viable.
#
# Design decisions:
#   - Entry point: test-specific script (scripts/docker-test.sh), not modified
#     bootstrap.sh — keeps WSL2 prerequisites contract clean
#   - Flake revision: same commit (COPY repo, not git clone) — tests exact revision
#   - Nix store cache: cold per run — acceptable for nightly frequency;
#     future: layer caching or GitHub Actions cache mount
#   - --impure: required for all nix build/eval (home-manager uses builtins.currentSystem)
#   - DOTFILES_*: set as ENV at container level

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install prerequisites for Nix installer (git for check.sh, curl+xz for installer)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    jq \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Nix via upstream installer (single-user, no daemon).
# The Determinate linux planner requires systemd for daemon mode, which Docker
# containers lack. Upstream --no-daemon installs root-owned single-user Nix
# without a daemon — correct for containers.
# Required packages: curl used above, xz-utils for the installer binary.
RUN mkdir -m 0755 /nix \
    && chown root /nix \
    && groupadd -r nixbld \
    && for i in $(seq 1 10); do useradd -r -g nixbld -G nixbld nixbld$i; done \
    && curl -fsSL https://nixos.org/nix/install -o /tmp/nix-install.sh \
    && sh /tmp/nix-install.sh --no-daemon \
    && mkdir -p /etc/nix \
    && printf '%s\n' 'experimental-features = nix-command flakes' > /etc/nix/nix.conf

# Ensure nix is in PATH for non-interactive shells
ENV PATH="/root/.nix-profile/bin:/nix/var/nix/profiles/default/bin:${PATH}"

# Copy repo at the tested revision into the container
COPY . /repo
WORKDIR /repo

# Required environment variables for flake evaluation
ENV DOTFILES_USERNAME=testuser
ENV DOTFILES_HOME=/home/testuser
ENV DOTFILES_DIRECTORY=/repo
ENV USER=testuser

# Run the Docker-specific test script
CMD ["bash", "/repo/scripts/docker-test.sh"]
