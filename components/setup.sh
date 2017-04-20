function setup() {
  comp_init 'setup'

  if [[ $verbose ]]; then
    verboseArg='--verbose'
  fi

  if [[ -z $no_pods ]]; then
    # This is the bundle command that circle uses 
    bundle check || bundle install --jobs 4 --retry 3

    # pod install may take 25 mins on circle if it has to download the master spec repo             
    bundle exec pod install $verboseArg || bundle exec pod install --repo-update $verboseArg
  fi

  if [[ -f Matchfile ]]; then
    bundle exec fastlane match development --readonly $verboseArg
    bundle exec fastlane match appstore --readonly $verboseArg
  fi

  msg 'Installing Git hooks'
  symlinkGitHooks

  comp_deinit

  carthage_bootstrap
}

function symlinkGitHooks() {
  hooksDir="$project_dir"/.git/hooks
  mkdir -p "$hooksDir"
  ln -fs ../../bin/git-hooks/submodule-update "$hooksDir"/post-checkout
  ln -fs ../../bin/git-hooks/submodule-update "$hooksDir"/post-merge
}

