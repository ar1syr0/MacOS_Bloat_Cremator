#!/bin/zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║     macOS Cremator — FULL REVERT by ar1syr0                  ║
# ║     Re-enables ALL services disabled by the cremator         ║
# ║     Run with: zsh revert_all_services.sh                     ║
# ╚══════════════════════════════════════════════════════════════╝

SUDO=/usr/bin/sudo
RM=/bin/rm
LAUNCHCTL=/bin/launchctl
SLEEP=/bin/sleep
OSASCRIPT_BIN=/usr/bin/osascript

echo ""
echo "================================================================"
echo "  macOS Cremator — FULL REVERT"
echo "  Restores ALL disabled services"
echo "================================================================"
echo ""

# Keep sudo alive
$SUDO -v || { echo "  ERROR: sudo failed."; exit 1; }
while true; do $SUDO -n true; $SLEEP 60; kill -0 "$$" || exit; done 2>/dev/null &

USER_PLIST="/private/var/db/com.apple.xpc.launchd/disabled.501.plist"
SYSTEM_PLIST="/private/var/db/com.apple.xpc.launchd/disabled.plist"

echo "  Clearing user-level disabled list..."
if [[ -f "$USER_PLIST" ]]; then
  $SUDO $RM -f "$USER_PLIST"
  echo "  Removed: $USER_PLIST"
else
  echo "  Not found (already clean): $USER_PLIST"
fi

echo ""
echo "  Clearing system-level disabled list..."
if [[ -f "$SYSTEM_PLIST" ]]; then
  $SUDO $RM -f "$SYSTEM_PLIST"
  echo "  Removed: $SYSTEM_PLIST"
else
  echo "  Not found (already clean): $SYSTEM_PLIST"
fi

echo ""
echo "================================================================"
echo "  DONE."
echo "================================================================"
echo ""
echo "  All services will be restored on next boot."
echo ""
echo "  Your Mac will reboot in 10 seconds..."
echo "  Close this window NOW to cancel the reboot."
echo ""
echo "================================================================"
echo ""

$SLEEP 10

$SUDO $LAUNCHCTL reboot system 2>/dev/null || $SUDO /sbin/reboot
