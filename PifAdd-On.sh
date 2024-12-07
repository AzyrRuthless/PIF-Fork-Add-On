#!/bin/bash

# Redirect all stderr (error and debugging output) to debug.txt
exec 2>debug.txt

function main_menu() {
  clear
  echo "PIF Fork by osm0sis Add-on, Created by Azyr"
  echo
  echo "Choose an option:"
  echo "1. Execute autopif"
  echo "2. Execute autopif + strong"
  echo "3. Enter the path to the build.prop file obtained from /vendor/build.prop"
  echo "4. Enter the path to the build.prop file obtained from /system/build.prop"
  echo "5. Enable script-only mode"
  echo "6. Disable script-only mode"
  echo
  echo -n "Your choice: "
  read initial_choice
  case $initial_choice in
    1) check_script_only_mode "autopif" ;;
    2) check_script_only_mode "autopif_strong" ;;
    3) check_script_only_mode "handle_vendor" ;;
    4) check_script_only_mode "handle_system" ;;
    5) enable_script_only_mode ;;
    6) disable_script_only_mode ;;
    *) echo "Invalid choice"; sleep 2; main_menu ;;
  esac
}

function check_script_only_mode() {
  if [ -f /data/adb/modules/playintegrityfix/script-only-mode ]; then
    clear
    echo "Script-only mode detected. Disabling it."
    rm /data/adb/modules/playintegrityfix/script-only-mode
    if [ $? -ne 0 ]; then
      echo "Error: Failed to disable script-only mode." >&2
      sleep 2
      return 1
    fi
  fi

  case $1 in
    autopif) execute_autopif ;;
    autopif_strong) execute_autopif_strong ;;
    handle_vendor) handle_build_prop "/vendor" ;;
    handle_system) handle_build_prop "/system" ;;
  esac
}

function execute_autopif() {
  clear
  local autopif_script="/data/adb/modules/playintegrityfix/autopif2.sh"
  if [ -f "$autopif_script" ]; then
    chmod +x "$autopif_script"
    "$autopif_script"
    if [ $? -ne 0 ]; then
      echo "Error: Failed to execute $autopif_script" >&2
      sleep 2
      return 1
    fi
    echo "Finished executing $autopif_script"
    sleep 2
  else
    echo "Script $autopif_script not found." >&2
    sleep 2
  fi
}

function execute_autopif_strong() {
  clear
  cd /data/adb/modules/playintegrityfix
  chmod +x autopif2.sh
  ./autopif2.sh --strong
  if [ $? -ne 0 ]; then
    echo "Error: Failed to execute autopif2.sh with --strong flag" >&2
    sleep 2
    return 1
  fi
  echo "Finished executing autopif2.sh with --strong flag"
  echo "Make sure that the other requirements/combinations are met. Results may vary depending on the ROM and device."
  sleep 2
}

function handle_build_prop() {
  clear
  local prop_type=$1
  local BUILD_PROP_PATH
  echo -n "Enter the path to the build.prop file from $prop_type: "
  read BUILD_PROP_PATH

  while [ ! -f "$BUILD_PROP_PATH" ]; do
    clear
    echo "build.prop file not found at the given path."
    echo -n "Please enter a valid path to the build.prop file from $prop_type: "
    read BUILD_PROP_PATH
  done

  if [ "$prop_type" == "/vendor" ] && grep -q "ro.product.system" "$BUILD_PROP_PATH"; then
    clear
    echo "It looks like this build.prop is from /system. Returning to main menu..."
    sleep 2
    main_menu
    return 0
  elif [ "$prop_type" == "/system" ] && grep -q "ro.product.vendor" "$BUILD_PROP_PATH"; then
    clear
    echo "It looks like this build.prop is from /vendor. Returning to main menu..."
    sleep 2
    main_menu
    return 0
  fi

  process_build_prop "$BUILD_PROP_PATH" "$prop_type"
}

function read_prop() {
  local prop_name=$1
  local build_prop_path=$2
  echo "Debugging: Searching for property: '$prop_name' in file: '$build_prop_path'" >&2

  # Try a more robust approach using grep and cut
  local prop_value=$(grep "^[[:space:]]*$prop_name[[:space:]]*=" "$build_prop_path" | cut -d '=' -f 2- | tr -d '\r')

  echo "Debugging: Raw value before cleaning: '$prop_value'" >&2

  # Remove leading/trailing whitespace and extra characters
  prop_value=$(echo "$prop_value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/[^[:print:]]//g')

  echo "Debugging: Cleaned value: '$prop_value'" >&2

  if [ -z "$prop_value" ]; then
    echo "Warning: Could not find property '$prop_name' in '$build_prop_path'" >&2
  fi
  printf '%s' "$prop_value"
}

function process_build_prop() {
  clear
  local BUILD_PROP_PATH=$1
  local prop_type=$2
  local prefix FINGERPRINT_PROP RELEASE_PROP ID_PROP INCREMENTAL_PROP TYPE_PROP TAGS_PROP SECURITY_PATCH_PROP SDK_INT_PROP UTC_DATE_PROP

  if [ "$prop_type" == "/vendor" ]; then
    prefix="ro.product.vendor"
    FINGERPRINT_PROP="ro.vendor.build.fingerprint"
    RELEASE_PROP="ro.vendor.build.version.release"
    ID_PROP="ro.vendor.build.id"
    INCREMENTAL_PROP="ro.vendor.build.version.incremental"
    TYPE_PROP="ro.vendor.build.type"
    TAGS_PROP="ro.vendor.build.tags"
    SECURITY_PATCH_PROP="ro.vendor.build.security_patch"
    SDK_INT_PROP="ro.vendor.build.version.sdk"
    UTC_DATE_PROP="ro.vendor.build.date.utc"
  else
    prefix="ro.product.system"
    FINGERPRINT_PROP="ro.system.build.fingerprint"
    RELEASE_PROP="ro.system.build.version.release"
    ID_PROP="ro.system.build.id"
    INCREMENTAL_PROP="ro.system.build.version.incremental"
    TYPE_PROP="ro.system.build.type"
    TAGS_PROP="ro.system.build.tags"
    SECURITY_PATCH_PROP="ro.build.version.security_patch"
    SDK_INT_PROP="ro.system.build.version.sdk"
    UTC_DATE_PROP="ro.system.build.date.utc"
  fi

  local MANUFACTURER=$(read_prop "$prefix.manufacturer" "$BUILD_PROP_PATH")
  echo "Debugging: MANUFACTURER=$MANUFACTURER" >&2
  local MODEL=$(read_prop "$prefix.model" "$BUILD_PROP_PATH")
  echo "Debugging: MODEL=$MODEL" >&2
  local FINGERPRINT=$(read_prop "$FINGERPRINT_PROP" "$BUILD_PROP_PATH")
  echo "Debugging: FINGERPRINT=$FINGERPRINT" >&2
  local BRAND=$(read_prop "$prefix.brand" "$BUILD_PROP_PATH")
  echo "Debugging: BRAND=$BRAND" >&2
  local PRODUCT=$(read_prop "$prefix.name" "$BUILD_PROP_PATH")
  echo "Debugging: PRODUCT=$PRODUCT" >&2
  local DEVICE=$(read_prop "$prefix.device" "$BUILD_PROP_PATH")
  echo "Debugging: DEVICE=$DEVICE" >&2
  local RELEASE=$(read_prop "$RELEASE_PROP" "$BUILD_PROP_PATH")
  echo "Debugging: RELEASE=$RELEASE" >&2
  local ID=$(read_prop "$ID_PROP" "$BUILD_PROP_PATH")
  echo "Debugging: ID=$ID" >&2
  local INCREMENTAL=$(read_prop "$INCREMENTAL_PROP" "$BUILD_PROP_PATH")
  echo "Debugging: INCREMENTAL=$INCREMENTAL" >&2
  local TYPE=$(read_prop "$TYPE_PROP" "$BUILD_PROP_PATH")
  echo "Debugging: TYPE=$TYPE" >&2
  local TAGS=$(read_prop "$TAGS_PROP" "$BUILD_PROP_PATH")
  echo "Debugging: TAGS=$TAGS" >&2
  local SECURITY_PATCH=$(read_prop "$SECURITY_PATCH_PROP" "$BUILD_PROP_PATH")
  echo "Debugging: SECURITY_PATCH=$SECURITY_PATCH" >&2
  local DEVICE_INITIAL_SDK_INT=$(read_prop "$SDK_INT_PROP" "$BUILD_PROP_PATH")
  echo "Debugging: DEVICE_INITIAL_SDK_INT=$DEVICE_INITIAL_SDK_INT" >&2
  local UTC_DATE=$(read_prop "$UTC_DATE_PROP" "$BUILD_PROP_PATH")
  echo "Debugging: UTC_DATE=$UTC_DATE" >&2

  # Validate UTC_DATE using grep
  if ! echo "$UTC_DATE" | grep -Eq '^[0-9]+$'; then
      echo "Warning: Invalid UTC_DATE format: '$UTC_DATE'. Setting RELEASE_DATE to 'Unknown'." >&2
      local RELEASE_DATE="Unknown"
  else
      local RELEASE_DATE=$(date -d @"$UTC_DATE" "+%Y-%m-%d" 2>/dev/null || echo "Unknown")
  fi
  echo "Debugging: RELEASE_DATE=$RELEASE_DATE" >&2

  # Call create_output with an array to preserve arguments
  create_output "$MANUFACTURER" "$MODEL" "$FINGERPRINT" "$BRAND" "$PRODUCT" "$DEVICE" "$RELEASE" "$ID" "$INCREMENTAL" "$TYPE" "$TAGS" "$SECURITY_PATCH" "$DEVICE_INITIAL_SDK_INT" "$RELEASE_DATE"
}

function create_output() {
  clear

  # Correctly receive the parameters using an array
  args=("$@")

  local MANUFACTURER="${args[0]}"
  local MODEL="${args[1]}"
  local FINGERPRINT="${args[2]}"
  local BRAND="${args[3]}"
  local PRODUCT="${args[4]}"
  local DEVICE="${args[5]}"
  local RELEASE="${args[6]}"
  local ID="${args[7]}"
  local INCREMENTAL="${args[8]}"
  local TYPE="${args[9]}"
  local TAGS="${args[10]}"
  local SECURITY_PATCH="${args[11]}"
  local DEVICE_INITIAL_SDK_INT="${args[12]}"
  local RELEASE_DATE="${args[13]}"

  OUTPUT=$(cat <<EOF
{
  // Build Fields
  "MANUFACTURER": "$MANUFACTURER",
  "MODEL": "$MODEL",
  "FINGERPRINT": "$FINGERPRINT",
  "BRAND": "$BRAND",
  "PRODUCT": "$PRODUCT",
  "DEVICE": "$DEVICE",
  "RELEASE": "$RELEASE",
  "ID": "$ID",
  "INCREMENTAL": "$INCREMENTAL",
  "TYPE": "$TYPE",
  "TAGS": "$TAGS",
  "SECURITY_PATCH": "$SECURITY_PATCH",
  "DEVICE_INITIAL_SDK_INT": "$DEVICE_INITIAL_SDK_INT",
  // System Properties
  "*.build.id": "$ID",
  "*.security_patch": "$SECURITY_PATCH",
  "*api_level": "$DEVICE_INITIAL_SDK_INT",
  // Estimated Release: $RELEASE_DATE
}
EOF
)
  echo
  echo "Choose an option for saving the output:"
  echo "1. Save to file custom.pif.json in the current directory"
  echo "2. Specify a path to save the output"
  echo "3. Save to /data/adb/modules/playintegrityfix/ with custom.pif.json and execute a script"
  echo
  echo -n "Your choice: "
  read choice
  case $choice in
    1)
      clear
      echo "$OUTPUT" > ./custom.pif.json
      echo "Output saved to ./custom.pif.json"
      sleep 2
      ;;
    2)
      clear
      echo -n "Enter the path to save the output: "
      read SAVE_PATH
      while [ ! -d "$SAVE_PATH" ]; do
        clear
        echo "Invalid path. Please enter a valid directory to save the output: "
        read SAVE_PATH
      done
      if [ -f "$SAVE_PATH/custom.pif.json" ]; then
        clear
        echo "File already exists. Deleting the old file..."
        sleep 2
        rm "$SAVE_PATH/custom.pif.json"
      fi
      echo "$OUTPUT" > "$SAVE_PATH/custom.pif.json"
      echo "Output saved to $SAVE_PATH/custom.pif.json"
      sleep 2
      ;;
    3)
      clear
      SAVE_PATH="/data/adb/modules/playintegrityfix"
      if [ -f "$SAVE_PATH/custom.pif.json" ]; then
        clear
        echo "File already exists. Deleting the old file..."
        sleep 2
        rm "$SAVE_PATH/custom.pif.json"
      fi
      echo "$OUTPUT" > "$SAVE_PATH/custom.pif.json"
      chmod +x "$SAVE_PATH/killgms.sh"
      "$SAVE_PATH/killgms.sh"
      echo "Output saved to $SAVE_PATH/custom.pif.json and executed killgms.sh"
      sleep 2
      ;;
    *)
      clear
      echo "Invalid choice"
      sleep 2
      # Return to the main menu instead of calling create_output again
      main_menu
      ;;
  esac
}

function enable_script_only_mode() {
  clear
  local script_only_file="/data/adb/modules/playintegrityfix/script-only-mode"
  if [ -f "$script_only_file" ]; then
    echo "Script-only mode is already enabled."
    echo
    sleep 2
    main_menu
    return 0
  fi

  if [ -f /data/adb/modules/playintegrityfix/custom.pif.json ]; then
    rm /data/adb/modules/playintegrityfix/custom.pif.json
    if [ $? -ne 0 ]; then
      echo "Error: Failed to delete custom.pif.json" >&2
      sleep 2
      return 1
    fi
    echo "Deleted custom.pif.json"
    sleep 2
  fi
  touch "$script_only_file"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to enable script-only mode." >&2
    sleep 2
    return 1
  fi
  echo "Enabled script-only mode"
  echo
  echo "Choose an option:"
  echo "1. Reboot Now"
  echo "2. Reboot Later"
  echo -n "Your choice: "
  read reboot_choice
  case $reboot_choice in
    1) reboot ;;
    2) echo "Rebooting later."; sleep 2 ;;
    *) echo "Invalid choice. Rebooting later."; sleep 2 ;;
  esac
}

function disable_script_only_mode() {
  clear
  local script_only_file="/data/adb/modules/playintegrityfix/script-only-mode"
  if [ ! -f "$script_only_file" ]; then
    echo "Script-only mode is not enabled."
    echo
    sleep 2
    main_menu
    return 0
  fi

  rm "$script_only_file"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to disable script-only mode" >&2
    sleep 2
    return 1
  fi
  echo "Disabled script-only mode."
  echo
  echo "Choose an option:"
  echo "1. Reboot Now"
  echo "2. Reboot Later"
  echo -n "Your choice: "
  read reboot_choice
  case $reboot_choice in
    1) reboot ;;
    2) echo "Rebooting later."; sleep 2 ;;
    *) echo "Invalid choice. Rebooting later."; sleep 2 ;;
  esac
}

main_menu
