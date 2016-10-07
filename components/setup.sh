function setup() {
  comp_init 'setup'

  git submodule update --init
  bundle install
  if [[ -f Matchfile ]]; then
    bundle exec match development --readonly
  fi

  if [[ -f Cartfile && ! -f .git/hooks/post-checkout ]]; then
    msg 'Installing Git hooks'
    (symlinkGitHooks)
    .git/hooks/post-checkout
  fi

  comp_deinit

  bundle exec pod repo update
  pod_install
  if [[ ! -d "Carthage/Build" ]]; then
    carthage_bootstrap
  fi
}

function symlinkGitHooks() {
  cd $project_dir/.git/hooks
  ln -s ../../bin/git-hooks/{pre-commit,post-checkout} .
}
