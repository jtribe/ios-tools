function setup() {
  comp_init 'setup'

  if [[ $verbose ]]; then
    verboseArg='--verbose'
  fi

  gem innstall bundler
  bundle install $verboseArg
  if [[ -f Matchfile ]]; then
    bundle exec match development --readonly $verboseArg
  fi

  if [[ -f Cartfile && ! -f .git/hooks/post-checkout ]]; then
    msg 'Installing Git hooks'
    symlinkGitHooks
  fi

  comp_deinit

  bundle exec pod check || bundle exec pod install $verboseArg || bundle exec pod install --repo-update $verboseArg

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
  hooksDir=$project_dir/.git/hooks
  mkdir -p $hooksDir
  ln -s ../../bin/git-hooks/{pre-commit,post-checkout} $hooksDir
}
