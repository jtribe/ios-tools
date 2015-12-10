#!/bin/bash

# Sets the short bundle version to the number of commits in the Git repository
# You can find the SHA for this number using:
# bundle_version=123; git log `git rev-list origin/master | awk "NR == $bundle_version"`

number_of_commits=$(git rev-list HEAD --count)
bundle_version=$number_of_commits

target_plist="$TARGET_BUILD_DIR/$INFOPLIST_PATH"
dsym_plist="$DWARF_DSYM_FOLDER_PATH/$DWARF_DSYM_FILE_NAME/Contents/Info.plist"
for plist in "$target_plist" "$dsym_plist"; do
  if [ -f "$plist" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $bundle_version" "$plist"
  fi
done
