#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# ==============================================================================
# Lubuntu Desktop-Core Installation Script (Lightweight LXQt Environment)
# ==============================================================================
# Description:
#   Installs the Lubuntu Desktop-Core environment (LXQt, Openbox, LightDM,
#   system configuration tools) without the heavy applications included in the
#   full lubuntu-desktop package. Ensures /etc/skel includes a Desktop directory
#   so new users inherit it automatically.
#
# Notes:
#   - Uses apt-get for predictable automation behavior.
#   - Does NOT install LibreOffice, Discover, or other large desktop apps.
#   - Script exits immediately on any error due to 'set -euo pipefail'.
# ==============================================================================

# ==============================================================================
# Step 1: Install Lubuntu Desktop-Core
# ==============================================================================
apt-get update -y
apt-get install -y lubuntu-desktop-core

# ==============================================================================
# Step 2: Install clipboard utilities
# ==============================================================================
apt-get install -y xsel xclip copyq

# ==============================================================================
# Step 3: Configure qterminal as the default terminal emulator
# ==============================================================================
# lubuntu-desktop-core includes qterminal; enforce it as the default.
update-alternatives --install \
  /usr/bin/x-terminal-emulator \
  x-terminal-emulator \
  /usr/bin/qterminal \
  50

# ==============================================================================
# Step 4: Ensure new users receive a Desktop directory
# ==============================================================================
mkdir -p /etc/skel/Desktop

# ==============================================================================
# Step 5: No wallpaper or theme adjustments required
# ==============================================================================
# Lubuntu Desktop-Core installs LXQt defaults without heavy theming.
# ==============================================================================

echo "NOTE: Lubuntu Desktop-Core installation complete."
