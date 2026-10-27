#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# ==============================================================================
# Lubuntu Cloud Edition Installation Script (Minimal LXQt Desktop)
# ==============================================================================
# Description:
#   Installs a lightweight LXQt desktop environment suitable for cloud VMs and
#   XRDP sessions: LXQt core components, Openbox, qterminal, PCManFM-Qt and
#   FeatherPad. Excludes the full Lubuntu application set (office suite, mail,
#   media apps) and any display manager, since XRDP starts its own X sessions.
#
# Notes:
#   - Script exits immediately on any error due to 'set -euo pipefail'.
# ==============================================================================

# ==============================================================================
# Step 1: Update package index
# ==============================================================================
apt-get update -y

# ==============================================================================
# Step 2: Install core LXQt desktop components
# ==============================================================================
# lxqt-core no longer pulls in lxqt-menu-data on 26.04 (LXQt 2.3); without it
# the panel has no application menu at all.
apt-get install -y \
  lxqt-core \
  lxqt-config \
  lxqt-panel \
  lxqt-session \
  lxqt-policykit \
  lxqt-sudo \
  lxqt-runner \
  lxqt-notificationd \
  lxqt-menu-data

# ==============================================================================
# Step 3: Install window manager, terminal, file manager, editor
# ==============================================================================
apt-get install -y \
  openbox \
  obconf-qt \
  pcmanfm-qt \
  qterminal \
  featherpad

# ==============================================================================
# Step 4: Install xdg-open / xdg-mime
# ==============================================================================
# How apps hand a link or file to "the default app". Neither package comes
# with lxqt-core, and without both, opening any link fails. Under
# XDG_CURRENT_DESKTOP=LXQt, xdg-utils delegates to qtxdg-mat (qtxdg-tools),
# so xdg-utils alone is not enough.
apt-get install -y xdg-utils qtxdg-tools

# ==============================================================================
# Step 5: Install clipboard utilities
# ==============================================================================
apt-get install -y xsel xclip copyq

# ==============================================================================
# Step 6: Configure qterminal as the default terminal emulator
# ==============================================================================
update-alternatives --install \
  /usr/bin/x-terminal-emulator \
  x-terminal-emulator \
  /usr/bin/qterminal \
  50

# ==============================================================================
# Step 7: Ensure new users receive a Desktop directory
# ==============================================================================
# The LXQt session defaults (/etc/xdg/lxqt/session.conf) are written by
# desktop.sh.
mkdir -p /etc/skel/Desktop

# ==============================================================================
# Step 8: Remove what a headless cloud desktop never uses
# ==============================================================================
# Several of these pop up authentication prompts or errors inside an XRDP
# session. gvfs's mount daemons hang PCManFM-Qt in remote sessions.
apt-get purge -y \
  bluez blueman cups cups-browsed cups-daemon system-config-printer \
  modemmanager speech-dispatcher orca \
  lxqt-powermanagement xscreensaver update-notifier \
  gvfs gvfs-backends gvfs-fuse \
  2>/dev/null || true
apt-get autoremove -y

# ==============================================================================
# Step 9: No display manager on the console
# ==============================================================================
# XRDP starts its own X sessions; a console login manager only competes for
# resources.
for dm in lightdm sddm; do
  systemctl disable "$dm" 2>/dev/null || true
done
systemctl set-default multi-user.target

echo "NOTE: Lubuntu Cloud Edition installation complete."
