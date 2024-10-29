#!/bin/bash

function main_menu() {
  echo "PIF Fork by osm0sis Add-on, Created by Azyr"
  echo
  echo "Choose an option:"
  echo "1. Execute autopif"
  echo "2. Enter the path to the build.prop file obtained from /vendor/build.prop"
  echo "3. Enter the path to the build.prop file obtained from /system/build.prop"
  echo "4. Enable script-only mode"
  echo "5. Disable script-only mode"
  echo
  read initial_choice
  case $initial_choice in
    1)
      check_script_only_mode "autopif"
      ;;
    2)
      check_script_only_mode "handle_vendor"
      ;;
    3)
      check_script_only_mode "handle_system"
      ;;
    4)
      enable_script_only_mode
      ;;
    5)
      disable_script_only_mode
      ;;
    *)
      echo
      echo "Invalid choice"
      main_menu
      ;;
  esac
}

function check_script_only_mode() {
  if [ -f /data/adb/modules/playintegrityfix/script-only-mode ]; then
    echo "Script-only mode detected. It will be disabled. Please reboot your device after this."
    rm /data/adb/modules/playintegrityfix/script-only-mode
    # Continue with the original intention
    case $1 in
      autopif)
        execute_autopif
        ;;
      handle_vendor)
        handle_build_prop "/vendor"
        ;;
      handle_system)
        handle_build_prop "/system"
        ;;
    esac
  else
    case $1 in
      autopif)
        execute_autopif
        ;;
      handle_vendor)
        handle_build_prop "/vendor"
        ;;
      handle_system)
        handle_build_prop "/system"
        ;;
    esac
  fi
}

function execute_autopif() {
  if [ -f /data/adb/modules/playintegrityfix/autopif2.sh ]; then
    chmod +x /data/adb/modules/playintegrityfix/autopif2.sh
    /data/adb/modules/playintegrityfix/autopif2.sh
    echo
    echo "Finished executing /data/adb/modules/playintegrityfix/autopif2.sh"
  else
    echo
    echo "Script /data/adb/modules/playintegrityfix/autopif2.sh not found."
  fi
}

function handle_build_prop() {
  local prop_type=$1
  local BUILD_PROP_PATH
  echo
  echo -n "Enter the path to the build.prop file from $prop_type: "
  read BUILD_PROP_PATH
  while [ ! -f "$BUILD_PROP_PATH" ]; do
    echo
    echo "build.prop file not found at the given path."
    echo -n "Please enter a valid path to the build.prop file from $prop_type: "
    read BUILD_PROP_PATH
  done
  if [ "$prop_type" == "/vendor" ] && grep -q "ro.product.system" "$BUILD_PROP_PATH"; then
    echo
    echo "It looks like this build.prop is from /system. Returning to main menu..."
    echo
    main_menu
  elif [ "$prop_type" == "/system" ] && grep -q "ro.product.vendor" "$BUILD_PROP_PATH"; then
    echo
    echo "It looks like this build.prop is from /vendor. Returning to main menu..."
    echo
    main_menu
  else
    process_build_prop "$BUILD_PROP_PATH" "$prop_type"
  fi
}

function read_prop() {
  local prop_name=$1
  local build_prop_path=$2
  local prop_value=$(grep -E "^$prop_name=" "$build_prop_path" | cut -d'=' -f2)
  echo "$prop_value"
}

function process_build_prop() {
  local BUILD_PROP_PATH=$1
  local prop_type=$2
  local prefix
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
  fi
  MANUFACTURER=$(read_prop "$prefix.manufacturer" "$BUILD_PROP_PATH")
  MODEL=$(read_prop "$prefix.model" "$BUILD_PROP_PATH")
  FINGERPRINT=$(read_prop "$FINGERPRINT_PROP" "$BUILD_PROP_PATH")
  BRAND=$(read_prop "$prefix.brand" "$BUILD_PROP_PATH")
  PRODUCT=$(read_prop "$prefix.name" "$BUILD_PROP_PATH")
  DEVICE=$(read_prop "$prefix.device" "$BUILD_PROP_PATH")
  RELEASE=$(read_prop "$RELEASE_PROP" "$BUILD_PROP_PATH")
  ID=$(read_prop "$ID_PROP" "$BUILD_PROP_PATH")
  INCREMENTAL=$(read_prop "$INCREMENTAL_PROP" "$BUILD_PROP_PATH")
  TYPE=$(read_prop "$TYPE_PROP" "$BUILD_PROP_PATH")
  TAGS=$(read_prop "$TAGS_PROP" "$BUILD_PROP_PATH")
  SECURITY_PATCH=$(read_prop "$SECURITY_PATCH_PROP" "$BUILD_PROP_PATH")
  DEVICE_INITIAL_SDK_INT=$(read_prop "$SDK_INT_PROP" "$BUILD_PROP_PATH")
  create_output "$prop_type"
}

function create_output() {
  local prop_type=$1
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
  "*api_level": "$DEVICE_INITIAL_SDK_INT"
}
EOF
)
  echo
  echo "Choose an option for saving the output:"
  echo "1. Save to file custom.pif.json in the current directory"
  echo "2. Specify a path to save the output"
  echo "3. Save to /data/adb/modules/playintegrityfix/ with custom.pif.json and execute a script"
  echo
  read choice
  case $choice in
    1)
      echo "$OUTPUT" > ./custom.pif.json
      echo
      echo "Output saved to ./custom.pif.json"
      ;;
    2)
      echo
      echo -n "Enter the path to save the output: "
      read SAVE_PATH
      while [ ! -d "$SAVE_PATH" ]; do
        echo
        echo "Invalid path. Please enter a valid path to save the output: "
        read SAVE_PATH
      done
      echo "$OUTPUT" > "$SAVE_PATH/custom.pif.json"
      echo
      echo "Output saved to $SAVE_PATH/custom.pif.json"
      ;;
    3)
      check_script_only_mode
      SAVE_PATH="/data/adb/modules/playintegrityfix"
      echo "$OUTPUT" > "$SAVE_PATH/custom.pif.json"
      echo
      echo "Output saved to $SAVE_PATH/custom.pif.json"
      ;;
    *)
      echo
      echo "Invalid choice"
      create_output
      ;;
  esac
}

function enable_script_only_mode() {
  echo
  if [ -f /data/adb/modules/playintegrityfix/custom.pif.json ]; then
    rm /data/adb/modules/playintegrityfix/custom.pif.json
    if [ $? -eq 0 ]; then
      echo "Deleted custom.pif.json"
    else
      echo "Failed to delete custom.pif.json"
      return
    fi
  fi
  touch /data/adb/modules/playintegrityfix/script-only-mode
  if [ $? -eq 0 ]; then
    echo "Enabled script-only mode"
  else
    echo "Failed to enable script-only mode"
    return
  fi
  echo "Rebooting in 5 seconds..."
  sleep 5
  reboot
}

function disable_script_only_mode() {
  echo
  if [ -f /data/adb/modules/playintegrityfix/script-only-mode ]; then
    rm /data/adb/modules/playintegrityfix/script-only-mode
    if [ $? -eq 0 ]; then
      echo "Disabled script-only mode. Please reboot your device after this."
    else
      echo "Failed to disable script-only mode"
    fi
  else
    echo "Script-only mode is not enabled."
  fi
}

main_menu
