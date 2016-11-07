function unit_tests() {
  comp_init 'test'
  if [[ -n $TEST_SCHEME ]]; then
    msg 'Running unit tests'
    run_tests "$TEST_SCHEME"
  else
    msg 'No TEST_SCHEME defined - skipping unit tests'
  fi
  comp_deinit
}

function ui_tests() {
  comp_init 'test'
  if [[ -n $UI_TEST_SCHEME ]]; then
    msg 'Running UI tests'
    run_tests "$UI_TEST_SCHEME"
  else
    msg 'No UI_TEST_SCHEME defined - skipping UI tests'
  fi
  comp_deinit
}

function run_tests() {
  scheme="$1"

  check_deps 'xcodebuild' 'xcpretty'
  cd "$project_dir"

  if [[ -n $clean ]]; then
    clean_build='clean'
  fi
  if [[ -n $WORKSPACE ]]; then
    workspace="-workspace $WORKSPACE"
  fi
  xcodebuild \
      $workspace \
      -scheme "$scheme" \
      -sdk iphonesimulator \
      -destination "$destination" \
      $clean_build test #\
#    | bundle exec xcpretty --report junit
}
