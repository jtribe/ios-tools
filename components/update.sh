function update() {
  comp_init 'update'
  check_deps 'git'
  if [[ -z $no_git ]]; then
    git_update
  fi
  comp_deinit
  if [[ -z $no_dependencies ]]; then
    pod_install
    carthage_bootstrap
  fi
}

function git_update() {
  msg 'Fetching and merging from upstream'
  git pull --ff-only
  git_submodule_update
}

function git_submodule_update() {
  msg 'Updating submodules'
  git submodule sync
  git submodule update --init
}
