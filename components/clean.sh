function clean() {
  comp_init 'clean'
  rm -rf ~/Library/Developer/Xcode/DerivedData/$PROJECT-*
  msg "Deleted all DerivedData for $PROJECT"
  comp_deinit
}
