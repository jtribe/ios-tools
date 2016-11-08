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
    # Make sure the simulator has hardware keyboard disabled for UI tests and give it time to launch
    msg 'Configuring simulator'
    killall Simulator || echo "No simulator running"
    defaults write com.apple.iphonesimulator ConnectHardwareKeyboard 0
    xcrun instruments -w '547B1B63-3F66-4E5B-8001-F78F2F1CDEA7' || true
    sleep 15

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
      $clean_build test \
    | bundle exec xcpretty --report junit
}
