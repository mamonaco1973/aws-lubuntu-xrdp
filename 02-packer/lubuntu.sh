#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# ==============================================================================
# Minimal Lubuntu Desktop Installation Script (LXQt-Core Environment)
# ==============================================================================
# Description:
#   Installs a minimal LXQt desktop environment using lxqt-core, openbox,
#   qterminal, and essential tools. Ensures /etc/skel includes a Desktop
#   directory so new users inherit the folder automatically.
#
# Notes:
#   - Uses apt-get for predictable automation behavior.
#   - Installs only LXQt core components, not the full lubuntu-desktop bundle.
#   - Script exits on any error due to 'set -euo pipefail'.
# ==============================================================================

# ==============================================================================
# Step 1: Install minimal LXQt components and window manager
# ==============================================================================
apt-get update -y
apt-get install -y lxqt-core openbox pcmanfm-qt qterminal

# ==============================================================================
# Step 2: Install clipboard utilities
# ==============================================================================
apt-get install -y xsel xclip copyq

# ==============================================================================
# Step 3: Configure qterminal as the default terminal emulator
# ==============================================================================
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
# Step 5: Skip wallpaper configuration for minimal LXQt
# ==============================================================================
# LXQt-Core does not install wallpapers or themes; nothing to validate here.
# ==============================================================================

echo "NOTE: Minimal LXQt desktop installation complete."
