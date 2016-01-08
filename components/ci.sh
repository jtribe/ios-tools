function ci_setup() {
  comp_init 'ci-setup'

  bundle exec match appstore --readonly

  comp_deinit
}
