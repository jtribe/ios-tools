function setup() {
  comp_init 'setup'

  git submodule update --init
  bundle install
  if [[ -f Matchfile ]]; then
    bundle exec match development --readonly
  fi
  comp_deinit

  bundle exec pod repo update
  pod_install
  carthage_bootstrap
}
