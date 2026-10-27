#!/bin/bash
set -euo pipefail

# ================================================================================
# Desktop Icon Provisioning Script (System-Wide Defaults)
# ================================================================================
# Description:
#   Creates trusted symlinks for selected applications inside /etc/skel/Desktop.
#   These symlinks ensure that all newly created users receive desktop icons
#   without the XFCE/LXQT "untrusted application launcher" warning dialog.
#
# Notes:
#   - Works for XFCE, MATE, LXQT and most desktop environments using .desktop files.
#   - Only affects *new* users created after this script runs.
#   - Symlinks are used instead of copied launchers to preserve trust flags.
# ================================================================================

# ================================================================================
# Configuration: Applications to appear on every new user's desktop
# ================================================================================
APPS=(
  /usr/share/applications/google-chrome.desktop
  /var/lib/snapd/desktop/applications/firefox_firefox.desktop
  /usr/share/applications/com.microsoft.VSCode.desktop
  /usr/share/applications/postman.desktop
  /usr/share/applications/onlyoffice-desktopeditors.desktop
)

SKEL_DESKTOP="/etc/skel/Desktop"

# ================================================================================
# Step 1: Ensure the skeleton Desktop directory exists
# ================================================================================
echo "NOTE: Ensuring /etc/skel/Desktop exists..."
mkdir -p "$SKEL_DESKTOP"

# ================================================================================
# Step 2: Create trusted symlinks for all selected applications
# ================================================================================
echo "NOTE: Creating trusted symlinks in /etc/skel/Desktop..."

for src in "${APPS[@]}"; do
  if [[ -f "$src" ]]; then
    filename=$(basename "$src")
    ln -sf "$src" "$SKEL_DESKTOP/$filename"
    echo "NOTE: Added $filename (trusted symlink)"
  else
    echo "WARNING: $src not found, skipping"
  fi
done

echo "NOTE: All new users will receive these desktop icons without trust prompts."

# ================================================================================
# Step 3: Firefox as the default browser
# ================================================================================
# LXQt has no equivalent of Xfce's helpers.rc: it (and xdg-open) resolve the
# browser from the XDG MIME defaults. System-wide defaults live in
# /etc/xdg/mimeapps.list; the .desktop file is the one snapd generates.

FIREFOX_DESKTOP=/var/lib/snapd/desktop/applications/firefox_firefox.desktop
test -f "$FIREFOX_DESKTOP"
sudo tee /etc/xdg/mimeapps.list >/dev/null <<'EOF'
[Default Applications]
x-scheme-handler/http=firefox_firefox.desktop
x-scheme-handler/https=firefox_firefox.desktop
text/html=firefox_firefox.desktop
application/xhtml+xml=firefox_firefox.desktop
EOF

# Fail the build here, not in a user's session, if LXQt doesn't resolve it.
default_browser=$(cd /tmp && env HOME=/root XDG_CURRENT_DESKTOP=LXQt \
  XDG_DATA_DIRS=/usr/local/share:/usr/share:/var/lib/snapd/desktop \
  xdg-mime query default x-scheme-handler/https)
echo "NOTE: LXQt default browser: ${default_browser}"
test "$default_browser" = "firefox_firefox.desktop"

# ================================================================================
# Step 4: Lubuntu configurations for XRDP
# ================================================================================
# On 26.04 (LXQt 2.3):
#   - The panel's menu is "fancymenu"; the classic "mainmenu" plugin does not
#     load.
#   - The Debian branding theme ("debian") styles only the old menu button,
#     so fancymenu's button is drawn blank. Any upstream theme draws it.

sudo mkdir -p /etc/xdg/lxqt /etc/xdg/pcmanfm-qt/lxqt

# Specify default applications and window manager

sudo tee /etc/xdg/lxqt/session.conf >/dev/null <<'EOF'
[Environment]
BROWSER=firefox-snap
TERM=qterminal

[General]
window_manager=openbox
EOF

# Configure LXQt panel with essential plugins and quicklaunchers
# Plugins that misbehave without local hardware (volume, battery,
# power management) are left out of the panel.

sudo tee /etc/xdg/lxqt/panel.conf >/dev/null <<EOF
[General]
iconTheme=Papirus-Dark

[kbindicator]
alignment=Right
type=kbindicator

[quicklaunch]
alignment=Left
apps\\1\\desktop=/usr/share/applications/pcmanfm-qt.desktop
apps\\2\\desktop=/usr/share/applications/qterminal.desktop
apps\\3\\desktop=/usr/share/applications/featherpad.desktop
apps\\4\\desktop=${FIREFOX_DESKTOP}
apps\\size=4
type=quicklaunch

[quicklaunch2]
alignment=left
apps\\1\\desktop=/usr/share/applications/lxqt-leave.desktop
apps\\size=1
type=quicklaunch

[fancymenu]
type=fancymenu
alignment=Left

[panel1]
plugins=fancymenu, showdesktop, desktopswitch, quicklaunch, taskbar, tray, statusnotifier, worldclock, quicklaunch2

[taskbar]
buttonWidth=200
raiseOnCurrentDesktop=true
EOF

# Configure PCManFM-Qt to show Desktop shortcuts and set default wallpaper

sudo tee /etc/xdg/pcmanfm-qt/lxqt/settings.conf >/dev/null <<'EOF'
[Desktop]
DesktopShortcuts=Home
Wallpaper=/usr/share/lxqt/themes/debian/wallpaper.svg
WallpaperMode=zoom
WallpaperRandomize=false

[System]
FallbackIconThemeName=oxygen
Terminal=qterminal

[Window]
AlwaysShowTabs=true

[Behavior]
QuickExec=true
EOF

sudo sed -i 's/^theme=debian$/theme=dark/' /etc/xdg/lxqt/lxqt.conf
grep -q '^theme=dark$' /etc/xdg/lxqt/lxqt.conf
