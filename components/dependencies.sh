function pod_install() {
  comp_init 'dependencies'

  if [[ -f Podfile ]]; then
    check_deps 'pod'
    msg 'Installing CocoaPods'
    old_args=$args
    if [[ -z $clean ]]; then
      args="--no-repo-update $args"
    fi
    if [[ $verbose ]]; then
      args="--verbose $args"
    fi
    bundle exec pod install $args $@
    args=$old_args
  fi
  comp_deinit
}

function carthage_bootstrap() {
  comp_init 'dependencies'
  if [[ -f Cartfile ]]; then
    if ! cmp -s Cartfile.resolved Carthage/Cartfile.resolved; then
      check_deps 'carthage'
      msg 'Installing Carthage packages'
      run_carthage bootstrap
      cp Cartfile.resolved Carthage
    else
      msg 'Carthage packages up to date - skipping'
    fi
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
  if [[ $verbose ]]; then
    args="--verbose $args"
  fi
  carthage $@ $CARTHAGE_OPTS $args
}
