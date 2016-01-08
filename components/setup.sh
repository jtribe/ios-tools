function setup() {
  comp_init 'setup'
  bundle install
  bundle exec match development --readonly
  comp_deinit

  pod_install
  carthage_bootstrap
}
