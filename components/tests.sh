function unit_tests() {
  comp_init 'tests'
  msg 'Running unit tests'
  run_tests "$TEST_SCHEME"
  comp_deinit
}

function ui_tests() {
  comp_init 'tests'
  msg 'Running UI tests'
  run_tests "$UI_TEST_SCHEME"
  comp_deinit
}

function run_tests() {
  scheme="$1"

  check_deps 'xcodebuild' 'xcpretty'
  cd "$project_dir"

  clean_build=''
  if [[ -n $clean ]]; then
    clean_build='clean'
  fi
  xcpretty_args="$XCPRETTY_OUTPUT"
  xcodebuild \
      -workspace "$WORKSPACE" \
      -scheme "$scheme" \
      -sdk iphonesimulator \
      -destination "$destination" \
      $clean_build test \
    | bundle exec xcpretty $xcpretty_args
}
