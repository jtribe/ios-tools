function setup() {
  comp_init 'setup'

  bundle install
  if [[ -f Matchfile ]]; then
    bundle exec match development --readonly
  fi

  if [[ -f Cartfile && ! -f .git/hooks/post-checkout ]]; then
    msg 'Installing Git hooks'
    (symlinkGitHooks)
  fi

  comp_deinit

  if [[ $verbose ]]; then
    verboseArg='--verbose'
  fi
  bundle exec pod repo update $verboseArg
  pod_install

  if [[ -f Cartfile ]]; then
    if [[ -f Carthage/Build.tar.gz ]]; then
      .git/hooks/post-checkout
    fi
    if [[ ! -d "Carthage/Build" ]]; then
      carthage_bootstrap
    fi
    .git/hooks/pre-commit
  fi
}

function symlinkGitHooks() {
  cd $project_dir/.git/hooks
  ln -s ../../bin/git-hooks/{pre-commit,post-checkout} .
}
