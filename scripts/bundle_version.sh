git=$(sh /etc/profile; which git)
number_of_commits=$("$git" rev-list HEAD --count)

bundle_version=$number_of_commits

target_plist="$TARGET_BUILD_DIR/$INFOPLIST_PATH"
dsym_plist="$DWARF_DSYM_FOLDER_PATH/$DWARF_DSYM_FILE_NAME/Contents/Info.plist"

for plist in "$target_plist" "$dsym_plist"; do
  if [ -f "$plist" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $bundle_version" "$plist"
  fi
done
