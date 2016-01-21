function itunes_connect() {
  comp_init 'itunes_connect'
  check_deps 'bundle'

  bundle exec match appstore --readonly --verbose
  security find-identity -p codesigning

  msg "Building archive"
  clean_build=''
  if [[ -n $clean ]]; then
    clean_build='--clean'
  fi
  if [[ "$WORKSPACE" ]]; then
    workspace="--workspace '$WORKSPACE'"
  fi
  bundle exec gym build \
    $workspace \
    --scheme "$SCHEME" \
    $clean_build

  msg "Submitting to iTunes Connect"
  bundle exec deliver run \
    --app_identifier "$BUNDLE_IDENTIFIER" \
    --username "$ITC_USER" \
    --force true

  comp_deinit
}
