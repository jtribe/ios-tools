#!/usr/bin/env bash

git=$(sh /etc/profile; which git)

bundle_version=$1

if [[ -z $bundle_version ]]; then
  # If not provided as a command line argument, use the 1
  bundle_version=1
fi

target_plist="$TARGET_BUILD_DIR/$INFOPLIST_PATH"
dsym_plist="$DWARF_DSYM_FOLDER_PATH/$DWARF_DSYM_FILE_NAME/Contents/Info.plist"

for plist in "$target_plist" "$dsym_plist"; do
  if [ -f "$plist" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $bundle_version" "$plist"
  fi
done
