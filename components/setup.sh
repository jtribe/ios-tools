function setup() {
  comp_init 'setup'

  if [[ $verbose ]]; then
    verboseArg='--verbose'
  fi

  if [[ -z $no_pods ]]; then
    # This is the bundle command that circle uses 
    bundle check || bundle install --jobs 4 --retry 3

    # pod check doesn't seem to know when the Pods cache is out of date on CircleCI, 
    # so force an install if a pod was updated by a developer
    diff Podfile.lock Pods/Manifest.lock > /dev/null || bundle exec pod install

    # pod install may take 25 mins on circle if it has to download the master spec repo             
    bundle exec pod check || bundle exec pod install $verboseArg || bundle exec pod install --repo-update $verboseArg
  fi

  if [[ -f Matchfile ]]; then
    bundle exec fastlane match development --readonly $verboseArg
    bundle exec fastlane match appstore --readonly $verboseArg
  fi

  if [[ -f Cartfile && ! -f .git/hooks/post-checkout ]]; then
    msg 'Installing Git hooks'
    symlinkGitHooks
  fi

  comp_deinit

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
