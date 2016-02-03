function pod_install() {
  comp_init 'dependencies'
  if [[ -f Podfile ]]; then
    check_deps 'pod'
    msg 'Installing CocoaPods'
    if [[ -z $clean ]]; then
      args="--no-repo-update $args"
    fi
    bundle exec pod install $args $@
  fi
  comp_deinit
}

function carthage_bootstrap() {
  comp_init 'dependencies'
  if [[ -f Cartfile ]]; then
    check_deps 'carthage'
    msg 'Installing Carthage packages'
    run_carthage bootstrap
  fi
  comp_deinit
}

function carthage_update() {
  comp_init 'dependencies'
  if [[ -f Cartfile ]]; then
    check_deps 'carthage'
    msg 'Installing Carthage packages'
    run_carthage update
  fi
  comp_deinit
}

function run_carthage() {
  carthage $@ --platform iOS
}
