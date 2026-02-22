#!/bin/zsh
#      macOS Full Bloat Cremator by ar1syr0 x Claude 2026   
#      Kills background services AND removes unwanted apps      
#       Run with: zsh full_bloat_cremator.sh    
#
#    This process requires disabling core macOS security features. That's not a warning to scare you off —
# it's a warning so you don't brick your machine and blame me. Do it wrong and you'll be staring at a flashing folder of doom.
#
# Prerequisites:
#   1. Disable FileVault (System Settings > Privacy & Security)
#   2. Boot into Recovery and run:
#        csrutil disable
#        csrutil authenticated-root disable
#   3. Reboot and run this script
#
# To revert services:
#   sudo rm -r /private/var/db/com.apple.xpc.launchd/*
#   Then reboot.
#
# To revert apps:
#   Reinstall from App Store or restore from Time Machine.
#   System apps return automatically after macOS updates.

# -------------------------------------------------------
# Hardcode every binary — zero PATH dependency
# -------------------------------------------------------
SUDO=/usr/bin/sudo
LAUNCHCTL=/bin/launchctl
PLUTIL=/usr/bin/plutil
RM=/bin/rm
OSASCRIPT_BIN=/usr/bin/osascript
SLEEP=/bin/sleep
MOUNT=/sbin/mount
UMOUNT=/sbin/umount
MKDIR=/bin/mkdir
RMDIR=/bin/rmdir
AWK=/usr/bin/awk
SED=/usr/bin/sed
GREP=/usr/bin/grep
UNAME=/usr/bin/uname
BLESS=/usr/sbin/bless

# -------------------------------------------------------
# Printed banner
# -------------------------------------------------------
echo ""
echo "================================================================"
echo "   macOS Full Bloat Cremator by ar1syr0 x Claude 2026"
echo "   Kills background services AND removes unwanted apps"
echo "   Run with: zsh full_bloat_cremator.sh"
echo "   Disclaimer: Created for Personal Use"
echo "   process requires disabling core macOS security features"
echo "   don't brick your machine and blame me"
echo "================================================================"
echo ""
echo "  Prerequisites:"
echo "    1. FileVault disabled"
echo "    2. In Recovery: csrutil disable"
echo "    3. In Recovery: csrutil authenticated-root disable"
echo ""
echo "  To revert services:"
echo "    sudo rm -r /private/var/db/com.apple.xpc.launchd/*"
echo "    Then reboot."
echo ""
echo "  To revert apps:"
echo "    Reinstall from App Store or Time Machine."
echo "    System apps return automatically after macOS updates."
echo ""
echo "================================================================"
echo ""

# -------------------------------------------------------
# Grab sudo upfront and keep it alive throughout
# -------------------------------------------------------
echo "  Requesting sudo privileges..."
echo ""
$SUDO -v || { echo "  ERROR: sudo failed. Are you an admin?"; exit 1; }
while true; do $SUDO -n true; $SLEEP 60; kill -0 "$$" || exit; done 2>/dev/null &

# -------------------------------------------------------
# PHASE 1 — Kill background services
# -------------------------------------------------------
echo "================================================================"
echo "  PHASE 1 — Terminating background services"
echo "================================================================"
echo ""

TOTAL=0
DISABLED=0
ALREADY_OFF=0
FAILED=0

# -------------------------------------------------------
# Cache plist state once using plutil -p
# Format: "com.apple.service" => 1  (disabled)
#         "com.apple.service" => 0  (enabled)
# Much more reliable than parsing launchctl print-disabled
# output which varies across macOS versions
# -------------------------------------------------------
USER_PLIST="/private/var/db/com.apple.xpc.launchd/disabled.501.plist"
SYSTEM_PLIST="/private/var/db/com.apple.xpc.launchd/disabled.plist"

echo "  Caching current service state..."
USER_PLIST_CACHE=$($PLUTIL -p "$USER_PLIST" 2>/dev/null || echo "")
SYSTEM_PLIST_CACHE=$($SUDO $PLUTIL -p "$SYSTEM_PLIST" 2>/dev/null || echo "")
echo "  Done. Starting service cremation..."
echo ""

# -------------------------------------------------------
# Core disable function
# Checks plist cache first to accurately detect
# already-disabled services on repeat runs
# -------------------------------------------------------
disable_service() {
  local type="$1"
  local name="$2"
  TOTAL=$((TOTAL + 1))

  if [[ "$type" == "user" ]]; then
    if echo "$USER_PLIST_CACHE" | $GREP -qF "\"${name}\" => 1"; then
      ALREADY_OFF=$((ALREADY_OFF + 1))
      echo "    [skip] ${name}"
      return
    fi
    $LAUNCHCTL bootout gui/501/${name} 2>/dev/null
    $LAUNCHCTL disable gui/501/${name} 2>/dev/null
    DISABLED=$((DISABLED + 1))
    echo "    [off]  ${name}"
  else
    if echo "$SYSTEM_PLIST_CACHE" | $GREP -qF "\"${name}\" => 1"; then
      ALREADY_OFF=$((ALREADY_OFF + 1))
      echo "    [skip] ${name}"
      return
    fi
    $SUDO $LAUNCHCTL bootout system/${name} 2>/dev/null
    $SUDO $LAUNCHCTL disable system/${name} 2>/dev/null
    DISABLED=$((DISABLED + 1))
    echo "    [off]  ${name}"
  fi
}

section() {
  echo ""
  echo "  -- $1 --"
}

# ===============================================================
# USER-LEVEL AGENTS (gui/501)
# ===============================================================
echo "  USER AGENTS"
echo "  -------------------------------------------------------"

section "Siri and AI"
disable_service user 'com.apple.assistant_service'
disable_service user 'com.apple.assistantd'
disable_service user 'com.apple.assistant_cdmd'
disable_service user 'com.apple.corespeechd'
disable_service user 'com.apple.siriactionsd'
disable_service user 'com.apple.Siri.agent'
disable_service user 'com.apple.siriinferenced'
disable_service user 'com.apple.sirittsd'
disable_service user 'com.apple.SiriTTSTrainingAgent'
disable_service user 'com.apple.siriknowledged'

section "Apple Intelligence"
disable_service user 'com.apple.intelligenceflowd'
disable_service user 'com.apple.intelligencecontextd'
disable_service user 'com.apple.intelligenceplatformd'
disable_service user 'com.apple.generativeexperiencesd'
disable_service user 'com.apple.mediaanalysisd'
disable_service user 'com.apple.naturallanguaged'
disable_service user 'com.apple.knowledgeconstructiond'
disable_service user 'com.apple.knowledge-agent'

section "Analytics and Telemetry"
disable_service user 'com.apple.geoanalyticsd'
disable_service user 'com.apple.inputanalyticsd'
disable_service user 'com.apple.BiomeAgent'
disable_service user 'com.apple.biomesyncd'
disable_service user 'com.apple.UsageTrackingAgent'
disable_service user 'com.apple.triald'
disable_service user 'com.apple.parsec-fbf'
disable_service user 'com.apple.parsecd'

section "iCloud and Sync"
disable_service user 'com.apple.cloudd'
disable_service user 'com.apple.cloudpaird'
disable_service user 'com.apple.cloudphotod'
disable_service user 'com.apple.CloudSettingsSyncAgent'
disable_service user 'com.apple.iCloudNotificationAgent'
disable_service user 'com.apple.icloudmailagent'
disable_service user 'com.apple.iCloudUserNotifications'
disable_service user 'com.apple.icloud.searchpartyuseragent'
disable_service user 'com.apple.itunescloudd'
disable_service user 'com.apple.protectedcloudstorage.protectedcloudkeysyncing'
disable_service user 'com.apple.security.cloudkeychainproxy3'
disable_service user 'com.apple.replicatord'

section "Location and Routing"
disable_service user 'com.apple.CoreLocationAgent'
disable_service user 'com.apple.routined'
disable_service user 'com.apple.geodMachServiceBridge'
disable_service user 'com.apple.navd'
disable_service user 'com.apple.Maps.pushdaemon'
disable_service user 'com.apple.Maps.mapssyncd'
disable_service user 'com.apple.maps.destinationd'

section "Find My"
disable_service user 'com.apple.findmy.findmylocateagent'

section "Messages, FaceTime and Calls"
disable_service user 'com.apple.imagent'
disable_service user 'com.apple.imautomatichistorydeletionagent'
disable_service user 'com.apple.imtransferagent'
disable_service user 'com.apple.avconferenced'
disable_service user 'com.apple.CallHistoryPluginHelper'
disable_service user 'com.apple.telephonyutilities.callservicesd'
disable_service user 'com.apple.CommCenter-osx'

section "Screen Sharing and Continuity"
disable_service user 'com.apple.screensharing.agent'
disable_service user 'com.apple.screensharing.menuextra'
disable_service user 'com.apple.screensharing.MessagesAgent'
disable_service user 'com.apple.sidecar-hid-relay'
disable_service user 'com.apple.sidecar-relay'
disable_service user 'com.apple.SSInvitationAgent'

section "Apple Apps and Services"
disable_service user 'com.apple.gamed'
disable_service user 'com.apple.financed'
disable_service user 'com.apple.newsd'
disable_service user 'com.apple.weatherd'
disable_service user 'com.apple.watchlistd'
disable_service user 'com.apple.videosubscriptionsd'
disable_service user 'com.apple.passd'
disable_service user 'com.apple.remindd'
disable_service user 'com.apple.calaccessd'
disable_service user 'com.apple.homed'
disable_service user 'com.apple.photoanalysisd'
disable_service user 'com.apple.photolibraryd'
disable_service user 'com.apple.mediastream.mstreamd'
disable_service user 'com.apple.followupd'
disable_service user 'com.apple.tipsd'
disable_service user 'com.apple.helpd'

section "Ads and Promotions"
disable_service user 'com.apple.ap.adprivacyd'
disable_service user 'com.apple.ap.promotedcontentd'

section "Accessibility and Motion"
disable_service user 'com.apple.accessibility.MotionTrackingAgent'
disable_service user 'com.apple.accessibility.axassetsd'
disable_service user 'com.apple.voicebankingd'

section "Family and Screen Time"
disable_service user 'com.apple.familycircled'
disable_service user 'com.apple.familycontrols.useragent'
disable_service user 'com.apple.familynotificationd'
disable_service user 'com.apple.ScreenTimeAgent'
disable_service user 'com.apple.macos.studentd'

section "Data and Context"
disable_service user 'com.apple.dataaccess.dataaccessd'
disable_service user 'com.apple.duetexpertd'
disable_service user 'com.apple.suggestd'
disable_service user 'com.apple.ManagedClientAgent.enrollagent'

section "QuickLook"
disable_service user 'com.apple.quicklook'
disable_service user 'com.apple.quicklook.ui.helper'
disable_service user 'com.apple.quicklook.ThumbnailsAgent'

section "Time Machine"
disable_service user 'com.apple.TMHelperAgent'

# ===============================================================
# SYSTEM-LEVEL DAEMONS
# ===============================================================
echo ""
echo "  SYSTEM DAEMONS"
echo "  -------------------------------------------------------"

section "Analytics and Telemetry"
disable_service system 'com.apple.analyticsd'
disable_service system 'com.apple.audioanalyticsd'
disable_service system 'com.apple.wifianalyticsd'
disable_service system 'com.apple.ecosystemanalyticsd'
disable_service system 'com.apple.triald.system'

section "Apple Intelligence"
disable_service system 'com.apple.modelmanagerd'

section "iCloud and Sync"
disable_service system 'com.apple.cloudd'
disable_service system 'com.apple.icloud.searchpartyd'

section "Location"
disable_service system 'com.apple.locationd'

section "Find My"
disable_service system 'com.apple.findmymac'
disable_service system 'com.apple.findmymacmessenger'
disable_service system 'com.apple.findmy.findmybeaconingd'

section "Backups"
disable_service system 'com.apple.backupd'
disable_service system 'com.apple.backupd-helper'

section "Screen Sharing"
disable_service system 'com.apple.screensharing'

section "Family Controls"
disable_service system 'com.apple.familycontrols'

section "Networking"
disable_service system 'com.apple.netbiosd'
disable_service system 'com.apple.dhcp6d'
disable_service system 'com.apple.ftp-proxy'

section "Miscellaneous"
disable_service system 'com.apple.GameController.gamecontrollerd'
disable_service system 'com.apple.biomed'

# -------------------------------------------------------
# Phase 1 summary
# -------------------------------------------------------
echo ""
echo "================================================================"
echo "  PHASE 1 COMPLETE"
echo "================================================================"
echo ""
echo "  Total processed   : $TOTAL"
echo "  Disabled now      : $DISABLED"
echo "  Already disabled  : $ALREADY_OFF"
echo "  Failed            : $FAILED"
echo ""
echo "  Changes saved to:"
echo "  /private/var/db/com.apple.xpc.launchd/disabled.plist"
echo ""
if [[ $FAILED -gt 0 ]]; then
  echo "  NOTE: $FAILED service(s) could not be disabled."
  echo "  This is usually fine — they may not exist on this macOS version."
  echo ""
fi
echo "================================================================"
echo ""

$SLEEP 1

# -------------------------------------------------------
# PHASE 2 — Dynamic app removal
# -------------------------------------------------------
echo "================================================================"
echo "  PHASE 2 — App removal"
echo "================================================================"
echo ""

# -------------------------------------------------------
# Protected apps — never shown in removal dialog
# -------------------------------------------------------
PROTECTED=(
  "Finder" "Safari" "System Preferences" "System Settings"
  "App Store" "Terminal" "Activity Monitor" "Disk Utility"
  "Migration Assistant" "Installer" "System Information"
  "Keychain Access" "Console" "Directory Utility" "Screen Sharing"
  "Archive Utility" "Password Reset" "Ticket Viewer"
  "Boot Camp Assistant" "Automator" "Script Editor"
  "Digital Color Meter" "ColorSync Utility" "AirPort Utility"
  "Network Utility" "RAID Utility" "Startup Disk"
  "VoiceOver Utility" "Accessibility Inspector" "Remote Desktop"
  "Software Update" "Firmware Updater" "Crash Reporter"
  "Problem Reporter" "Simulator" "Xcode"
)

is_protected() {
  local check="$1"
  for p in "${PROTECTED[@]}"; do
    [[ "$check" == "$p" ]] && return 0
  done
  return 1
}

# -------------------------------------------------------
# Get root APFS device — strips snapshot suffix
# e.g. /dev/disk3s1s1 -> /dev/disk3s1
# -------------------------------------------------------
get_root_device() {
  $MOUNT | $GREP " on / " | $AWK '{print $1}' | $SED 's/s[0-9]*$//'
}

APP_REMOVED=0
APP_FAILED=0
MOUNTPOINT="$HOME/.bloat_mount_tmp"

# -------------------------------------------------------
# Remove app via direct APFS device mount + bless
# sudo mount -uw / does not work on macOS Big Sur+
# -------------------------------------------------------
remove_app() {
  local apppath="$1"
  local appname="$2"

  ROOT_DEV=$(get_root_device)

  if [[ -z "$ROOT_DEV" ]]; then
    echo "    ERROR: Could not determine root APFS device."
    APP_FAILED=$((APP_FAILED + 1))
    return 1
  fi

  echo "    Device     : $ROOT_DEV"
  echo "    Mountpoint : $MOUNTPOINT"

  $MKDIR -p "$MOUNTPOINT"

  $SUDO $MOUNT -o nobrowse -t apfs "$ROOT_DEV" "$MOUNTPOINT"
  if [[ $? -ne 0 ]]; then
    echo "    ERROR: Could not mount $ROOT_DEV"
    echo "    Ensure both csrutil and authenticated-root are disabled in Recovery."
    $RMDIR "$MOUNTPOINT" 2>/dev/null
    APP_FAILED=$((APP_FAILED + 1))
    return 1
  fi

  local mounted_app="${MOUNTPOINT}/${apppath#/}"

  echo "    Removing   : $mounted_app"
  $SUDO $RM -rf "$mounted_app"

  if [[ -e "$mounted_app" ]]; then
    echo "    ERROR: $appname still exists after removal."
    $SUDO $UMOUNT "$MOUNTPOINT"
    $RMDIR "$MOUNTPOINT" 2>/dev/null
    APP_FAILED=$((APP_FAILED + 1))
    return 1
  fi

  echo "    Blessing new snapshot..."
  local arch=$($UNAME -m)
  if [[ "$arch" == "arm64" ]]; then
    $SUDO $BLESS --mount "$MOUNTPOINT" --bootefi --create-snapshot
  else
    $SUDO $BLESS --folder "$MOUNTPOINT/System/Library/CoreServices" \
      --bootefi --create-snapshot
  fi

  if [[ $? -ne 0 ]]; then
    echo "    WARNING: bless failed — deletion may not survive reboot."
  else
    echo "    Snapshot blessed."
  fi

  $SUDO $UMOUNT "$MOUNTPOINT"
  $RMDIR "$MOUNTPOINT" 2>/dev/null

  echo "    Done: $appname removed"
  APP_REMOVED=$((APP_REMOVED + 1))
}

# -------------------------------------------------------
# Scan app directories
# -------------------------------------------------------
echo "  Scanning installed apps..."
echo ""

typeset -A APP_PATHS
APPLESCRIPT_ITEMS=""
FOUND_COUNT=0

for app in /System/Applications/*.app; do
  [[ -d "$app" ]] || continue
  name="${app:t:r}"
  is_protected "$name" && continue
  APP_PATHS[$name]="$app"
  APPLESCRIPT_ITEMS="${APPLESCRIPT_ITEMS}\"${name} [returns after updates]\", "
  echo "    [system] $name"
  FOUND_COUNT=$((FOUND_COUNT + 1))
done

for app in /Applications/*.app; do
  [[ -d "$app" ]] || continue
  name="${app:t:r}"
  is_protected "$name" && continue
  APP_PATHS[$name]="$app"
  APPLESCRIPT_ITEMS="${APPLESCRIPT_ITEMS}\"${name} [permanent]\", "
  echo "    [user]   $name"
  FOUND_COUNT=$((FOUND_COUNT + 1))
done

APPLESCRIPT_ITEMS="${APPLESCRIPT_ITEMS%, }"
echo ""
echo "  Found $FOUND_COUNT removable app(s)."
echo ""

# -------------------------------------------------------
# Show dialog if apps were found, otherwise skip
# Heredoc delimiter renamed to APPLE_EOF to avoid
# any conflict with the $OSASCRIPT_BIN variable
# -------------------------------------------------------
SELECTED=""

if [[ $FOUND_COUNT -gt 0 ]]; then
  SELECTED=$($OSASCRIPT_BIN <<APPLE_EOF
set appList to {${APPLESCRIPT_ITEMS}}
set chosen to choose from list appList with title "Mac Cremator - Phase 2 - ar1syr0" with prompt "Select apps to remove. Hold Cmd to select multiple.

[returns after updates] = removed now, comes back after macOS updates
[permanent] = gone for good, reinstall from App Store to restore

No undo. Choose carefully." OK button name "Remove Selected" cancel button name "Skip" with multiple selections allowed without empty selection allowed
if chosen is false then return ""
set output to ""
repeat with theItem in chosen
  set output to output & (theItem as string) & linefeed
end repeat
return output
APPLE_EOF
  )
fi

# -------------------------------------------------------
# Process selections
# -------------------------------------------------------
if [[ -z "$SELECTED" ]]; then
  echo "  App removal skipped."
  echo ""
else
  echo "  Removing selected apps..."
  echo ""

  while IFS= read -r chosen; do
    [[ -z "${chosen// }" ]] && continue
    chosen="${chosen## }"
    chosen="${chosen%% }"

    name="${chosen% \[returns after updates\]}"
    name="${name% \[permanent\]}"
    name="${name## }"
    name="${name%% }"

    [[ -z "$name" ]] && continue

    path="${APP_PATHS[$name]}"

    if [[ -z "$path" || ! -e "$path" ]]; then
      for dir in "/System/Applications" "/Applications"; do
        [[ -d "${dir}/${name}.app" ]] && path="${dir}/${name}.app" && break
      done
    fi

    if [[ -n "$path" && -e "$path" ]]; then
      remove_app "$path" "$name"
    else
      echo "    Not found: $name (already removed?)"
      APP_FAILED=$((APP_FAILED + 1))
    fi
    echo ""

  done <<< "$SELECTED"

  echo "  Apps removed  : $APP_REMOVED"
  echo "  Failed        : $APP_FAILED"
  echo ""
fi

# -------------------------------------------------------
# Final summary
# -------------------------------------------------------
echo "================================================================"
echo "  ALL DONE !"
echo "================================================================"
echo ""
echo "  Phase 1 — Services"
echo "    Disabled now     : $DISABLED"
echo "    Already disabled : $ALREADY_OFF"
echo "    Failed           : $FAILED"
echo ""
echo "  Phase 2 — Apps"
if [[ -n "$SELECTED" ]]; then
  echo "    Removed          : $APP_REMOVED"
  echo "    Failed           : $APP_FAILED"
else
  echo "    Skipped"
fi
echo ""
echo "  Reboot your Mac to apply all changes."
echo ""
echo "  To undo services:"
echo "    sudo rm -r /private/var/db/com.apple.xpc.launchd/*"
echo "    Then reboot."
echo ""
echo "================================================================"
echo ""

# ar1syr0 x Claude — 2026
