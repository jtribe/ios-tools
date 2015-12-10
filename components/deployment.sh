function itunes_connect() {
  comp_init 'itunes_connect'
  check_deps 'bundle'

  export FASTLANE_PASSWORD="$ITC_PASSWORD"

  msg "Building archive"
  clean_build=''
  if [[ -n $clean ]]; then
    clean_build='--clean'
  fi
  bundle exec gym build \
    --workspace "$WORKSPACE" \
    --scheme "$SCHEME" \
    $clean_build

  msg "Submitting to iTunes Connect"
  bundle exec deliver run \
    --app_identifier $BUNDLE_IDENTIFIER \
    --username $ITC_USER \
    --force true
}
