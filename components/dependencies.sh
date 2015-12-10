function pod_install() {
  comp_init 'dependencies'
  check_deps 'pod'
  msg 'Installing CocoaPods'
  if [[ -z $clean ]]; then
    args="--no-repo-update $args"
  fi
  bundle exec pod install $args $@
  comp_deinit
}

function carthage_bootstrap() {
  comp_init 'dependencies'
  check_deps 'carthage'
  msg 'Installing Carthage packages'
  run_carthage bootstrap
  comp_deinit
}

function carthage_update() {
  comp_init 'dependencies'
  check_deps 'carthage'
  msg 'Installing Carthage packages'
  run_carthage update
  comp_deinit
}

function run_carthage() {
  carthage $@ \
    --platform iOS
}
