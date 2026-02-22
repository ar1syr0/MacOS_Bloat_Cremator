#!/bin/zsh
#      macOS Full Bloat Cremator by ar1syr0 x Claude 2026   
#      Kills background services AND removes unwanted apps      
#      Run with: zsh full_bloat_cremator.sh    
#
# This process requires disabling core macOS security features. That's not a warning to scare you off —
# It's a warning so you don't brick your machine and blame me. Do it wrong and you'll be staring at a flashing folder of doom.
#
# Prerequisites for app removal only:
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
# Banner
# -------------------------------------------------------
echo ""
echo "================================================================"
echo "   macOS Safe Cremator — ar1syr0 x Claude 2026"
echo "   Use at your own risk "
echo "================================================================"
echo ""
echo "  Prerequisites (for App removal only):"
echo "    1. FileVault disabled"
echo "    2. In Recovery: csrutil disable"
echo "    3. In Recovery: csrutil authenticated-root disable"
echo ""
echo "  To revert services:"
echo "    sudo rm -f /private/var/db/com.apple.xpc.launchd/disabled.plist"
echo "    sudo rm -f /private/var/db/com.apple.xpc.launchd/disabled.501.plist"
echo "    Then reboot."
echo ""
echo "  To revert apps:"
echo "    Reinstall from App Store or Time Machine."
echo "    System apps return after macOS updates."
echo ""
echo "================================================================"
echo ""

# -------------------------------------------------------
# Grab sudo upfront and keep it alive
# -------------------------------------------------------
echo "  Requesting sudo privileges..."
$SUDO -v || { echo "  ERROR: sudo failed. Are you an admin?"; exit 1; }
while true; do $SUDO -n true; $SLEEP 60; kill -0 "$$" || exit; done 2>/dev/null &
echo ""

# -------------------------------------------------------
# Phase selection dialog
# -------------------------------------------------------
PHASE_CHOICE=$($OSASCRIPT_BIN <<APPLE_EOF
set choice to button returned of (display dialog "What would you like to do?" with title "Mac Safe Cremator — ar1syr0" buttons {"Both Phases", "Services Only", "Apps Only"} default button "Both Phases")
return choice
APPLE_EOF
)

echo "  Running: $PHASE_CHOICE"
echo ""

RUN_PHASE1=false
RUN_PHASE2=false

if   [[ "$PHASE_CHOICE" == "Both Phases"   ]]; then RUN_PHASE1=true; RUN_PHASE2=true
elif [[ "$PHASE_CHOICE" == "Services Only" ]]; then RUN_PHASE1=true
elif [[ "$PHASE_CHOICE" == "Apps Only"     ]]; then RUN_PHASE2=true
fi

# ===============================================================
# PHASE 1 — Safe service disabling
# ===============================================================
TOTAL=0; DISABLED=0; ALREADY_OFF=0; FAILED=0

if [[ "$RUN_PHASE1" == true ]]; then

echo "================================================================"
echo "  PHASE 1 — Disabling safe services"
echo "  (Telemetry · AI · Siri · Ads · Unused Apple daemons)"
echo "================================================================"
echo ""

USER_PLIST="/private/var/db/com.apple.xpc.launchd/disabled.501.plist"
SYSTEM_PLIST="/private/var/db/com.apple.xpc.launchd/disabled.plist"

echo "  Caching current service state..."
USER_CACHE=$($PLUTIL -p "$USER_PLIST" 2>/dev/null || echo "")
SYSTEM_CACHE=$($SUDO $PLUTIL -p "$SYSTEM_PLIST" 2>/dev/null || echo "")
echo "  Done. Starting cremation..."
echo ""

disable_service() {
  local type="$1"
  local name="$2"
  TOTAL=$((TOTAL + 1))
  if [[ "$type" == "user" ]]; then
    if echo "$USER_CACHE" | $GREP -qF "\"${name}\" => 1"; then
      ALREADY_OFF=$((ALREADY_OFF + 1))
      echo "    [skip] ${name}"; return
    fi
    $LAUNCHCTL bootout gui/501/${name} 2>/dev/null
    $LAUNCHCTL disable gui/501/${name} 2>/dev/null
  else
    if echo "$SYSTEM_CACHE" | $GREP -qF "\"${name}\" => 1"; then
      ALREADY_OFF=$((ALREADY_OFF + 1))
      echo "    [skip] ${name}"; return
    fi
    $SUDO $LAUNCHCTL bootout system/${name} 2>/dev/null
    $SUDO $LAUNCHCTL disable system/${name} 2>/dev/null
  fi
  DISABLED=$((DISABLED + 1))
  echo "    [off]  ${name}"
}

section() { echo ""; echo "  -- $1 --"; }

# ================================================================
# USER AGENTS
# ================================================================
echo "  USER AGENTS"
echo "  -------------------------------------------------------"

section "Siri and Voice"
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
disable_service user 'com.apple.voicebankingd'

section "Apple Intelligence"
disable_service user 'com.apple.intelligenceflowd'
disable_service user 'com.apple.intelligencecontextd'
disable_service user 'com.apple.intelligenceplatformd'
disable_service user 'com.apple.generativeexperiencesd'
disable_service user 'com.apple.mediaanalysisd'
disable_service user 'com.apple.naturallanguaged'
disable_service user 'com.apple.knowledgeconstructiond'
disable_service user 'com.apple.knowledge-agent'

section "Telemetry and Analytics"
disable_service user 'com.apple.BiomeAgent'
disable_service user 'com.apple.biomesyncd'
disable_service user 'com.apple.UsageTrackingAgent'
disable_service user 'com.apple.triald'
disable_service user 'com.apple.parsec-fbf'
disable_service user 'com.apple.parsecd'
disable_service user 'com.apple.inputanalyticsd'
disable_service user 'com.apple.geoanalyticsd'

section "Ads and Promotions"
disable_service user 'com.apple.ap.adprivacyd'
disable_service user 'com.apple.ap.promotedcontentd'

section "Suggestions"
disable_service user 'com.apple.suggestd'
disable_service user 'com.apple.duetexpertd'
disable_service user 'com.apple.followupd'

section "Unused Apple App Daemons"
disable_service user 'com.apple.newsd'
disable_service user 'com.apple.tipsd'
disable_service user 'com.apple.financed'
disable_service user 'com.apple.gamed'
disable_service user 'com.apple.watchlistd'
disable_service user 'com.apple.videosubscriptionsd'
disable_service user 'com.apple.mediastream.mstreamd'

section "Accessibility Telemetry"
disable_service user 'com.apple.accessibility.MotionTrackingAgent'
disable_service user 'com.apple.accessibility.axassetsd'

section "Family and Screen Time"
disable_service user 'com.apple.familycircled'
disable_service user 'com.apple.familycontrols.useragent'
disable_service user 'com.apple.familynotificationd'
disable_service user 'com.apple.ScreenTimeAgent'
disable_service user 'com.apple.macos.studentd'

section "MDM and Trial"
disable_service user 'com.apple.ManagedClientAgent.enrollagent'

# ================================================================
# SYSTEM DAEMONS
# ================================================================
echo ""
echo "  SYSTEM DAEMONS"
echo "  -------------------------------------------------------"

section "Telemetry and Analytics"
disable_service system 'com.apple.analyticsd'
disable_service system 'com.apple.audioanalyticsd'
disable_service system 'com.apple.wifianalyticsd'
disable_service system 'com.apple.ecosystemanalyticsd'
disable_service system 'com.apple.triald.system'

section "Apple Intelligence (system)"
disable_service system 'com.apple.modelmanagerd'

section "Game Controller"
disable_service system 'com.apple.GameController.gamecontrollerd'

# ================================================================
# INTENTIONALLY KEPT ALIVE — DO NOT DISABLE
# ================================================================
# com.apple.universalaccessd     WindowServer rendering hooks
# com.apple.ContextStoreAgent    Display context across sleep/wake
# com.apple.progressd            WindowServer UI dependency
# com.apple.chronod              Display event scheduling
# com.apple.rapportd             Device proximity / wake triggers
# com.apple.rapportd-user        Device proximity / wake triggers
# com.apple.sharingd             Sleep/wake handshake
# com.apple.coreduetd            Power/wake state decisions
# com.apple.locationd            Location-based wake triggers
# com.apple.cloudd               iCloud core sync
# com.apple.photolibraryd        Photos library integrity
# com.apple.quicklook*           Finder previews
# com.apple.homed                HomeKit state
# com.apple.remindd              Reminders notifications
# com.apple.calaccessd           Calendar data integrity
# com.apple.imagent              iMessage delivery
# com.apple.CoreLocationAgent    Maps / location services
# ================================================================

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
echo "  Preserved (wake/display/core):"
echo "  universalaccessd, coreduetd, ContextStoreAgent, progressd,"
echo "  chronod, rapportd, sharingd, locationd, cloudd, quicklook*"
echo ""
echo "================================================================"
echo ""

$SLEEP 1

else
  echo "================================================================"
  echo "  PHASE 1 — Skipped"
  echo "================================================================"
  echo ""
fi

# ===============================================================
# PHASE 2 — Dynamic app removal
# ===============================================================
APP_REMOVED=0; APP_FAILED=0; SELECTED=""

if [[ "$RUN_PHASE2" == true ]]; then

echo "================================================================"
echo "  PHASE 2 — App removal"
echo "================================================================"
echo ""

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
  for p in "${PROTECTED[@]}"; do [[ "$check" == "$p" ]] && return 0; done
  return 1
}

get_root_device() {
  $MOUNT | $GREP " on / " | $AWK '{print $1}' | $SED 's/s[0-9]*$//'
}

MOUNTPOINT="$HOME/.bloat_mount_tmp"

remove_app() {
  local apppath="$1"
  local appname="$2"
  ROOT_DEV=$(get_root_device)

  if [[ -z "$ROOT_DEV" ]]; then
    echo "    ERROR: Could not determine root APFS device."
    APP_FAILED=$((APP_FAILED + 1)); return 1
  fi

  echo "    Device     : $ROOT_DEV"
  echo "    Mountpoint : $MOUNTPOINT"
  $MKDIR -p "$MOUNTPOINT"

  $SUDO $MOUNT -o nobrowse -t apfs "$ROOT_DEV" "$MOUNTPOINT"
  if [[ $? -ne 0 ]]; then
    echo "    ERROR: Could not mount $ROOT_DEV"
    echo "    Ensure csrutil and authenticated-root are disabled in Recovery."
    $RMDIR "$MOUNTPOINT" 2>/dev/null
    APP_FAILED=$((APP_FAILED + 1)); return 1
  fi

  local mounted_app="${MOUNTPOINT}/${apppath#/}"
  echo "    Removing   : $mounted_app"
  $SUDO $RM -rf "$mounted_app"

  if [[ -e "$mounted_app" ]]; then
    echo "    ERROR: $appname still exists after removal."
    $SUDO $UMOUNT "$MOUNTPOINT"
    $RMDIR "$MOUNTPOINT" 2>/dev/null
    APP_FAILED=$((APP_FAILED + 1)); return 1
  fi

  echo "    Blessing new snapshot..."
  local arch=$($UNAME -m)
  if [[ "$arch" == "arm64" ]]; then
    $SUDO $BLESS --mount "$MOUNTPOINT" --bootefi --create-snapshot
  else
    $SUDO $BLESS --folder "$MOUNTPOINT/System/Library/CoreServices" \
      --bootefi --create-snapshot
  fi

  [[ $? -ne 0 ]] && echo "    WARNING: bless failed — deletion may not survive reboot." \
                 || echo "    Snapshot blessed."

  $SUDO $UMOUNT "$MOUNTPOINT"
  $RMDIR "$MOUNTPOINT" 2>/dev/null
  echo "    Done: $appname removed"
  APP_REMOVED=$((APP_REMOVED + 1))
}

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

if [[ $FOUND_COUNT -gt 0 ]]; then
  SELECTED=$($OSASCRIPT_BIN <<APPLE_EOF
set appList to {${APPLESCRIPT_ITEMS}}
set chosen to choose from list appList ¬
  with title "Mac Safe Cremator — Phase 2 — ar1syr0" ¬
  with prompt "Select apps to remove. Hold Cmd to select multiple.

[returns after updates] = removed now, comes back after macOS updates
[permanent] = gone for good, reinstall from App Store to restore

No undo. Choose carefully." ¬
  OK button name "Remove Selected" ¬
  cancel button name "Skip" ¬
  with multiple selections allowed ¬
  without empty selection allowed
if chosen is false then return ""
set output to ""
repeat with theItem in chosen
  set output to output & (theItem as string) & linefeed
end repeat
return output
APPLE_EOF
  )
fi

if [[ -z "$SELECTED" ]]; then
  echo "  App removal skipped."
  echo ""
else
  echo "  Removing selected apps..."
  echo ""

  while IFS= read -r chosen; do
    [[ -z "${chosen// }" ]] && continue
    chosen="${chosen## }"; chosen="${chosen%% }"
    name="${chosen% \[returns after updates\]}"
    name="${name% \[permanent\]}"
    name="${name## }"; name="${name%% }"
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

else
  echo "================================================================"
  echo "  PHASE 2 — Skipped"
  echo "================================================================"
  echo ""
fi

# -------------------------------------------------------
# Final summary
# -------------------------------------------------------
echo "================================================================"
echo "  ALL DONE, ar1syr0."
echo "================================================================"
echo ""
echo "  Phase 1 — Services"
if [[ "$RUN_PHASE1" == true ]]; then
  echo "    Disabled now     : $DISABLED"
  echo "    Already disabled : $ALREADY_OFF"
  echo "    Failed           : $FAILED"
else
  echo "    Skipped"
fi
echo ""
echo "  Phase 2 — Apps"
if [[ "$RUN_PHASE2" == true && -n "$SELECTED" ]]; then
  echo "    Removed          : $APP_REMOVED"
  echo "    Failed           : $APP_FAILED"
else
  echo "    Skipped"
fi
echo ""
echo "  Reboot your Mac to apply all changes."
echo ""
echo "  To undo services:"
echo "    sudo rm -f /private/var/db/com.apple.xpc.launchd/disabled.plist"
echo "    sudo rm -f /private/var/db/com.apple.xpc.launchd/disabled.501.plist"
echo "    Then reboot."
echo ""
echo "================================================================"
echo ""


# ar1syr0 x Claude — 2026
