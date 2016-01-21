function setup() {
  comp_init 'setup'
  bundle install
  if [[ -f Matchfile ]]; then
    bundle exec match development --readonly
  fi
  comp_deinit

  pod_install
  carthage_bootstrap
}
