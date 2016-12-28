function itunes_connect() {
  comp_init 'itunes-connect'
  check_deps 'bundle'

  if [ -z "$scheme" ]; then
    scheme=$PROD_SCHEME
  fi

  # make sure that we don't have a shallow clone so that bundle-version.sh has the whole history
  git fetch --unshallow || true

  # set up certificates and provisioning profiles
  bundle exec fastlane match appstore --readonly --verbose
  security find-identity -p codesigning

  msg "Building archive"
  clean_build=''
  if [[ -n $clean ]]; then
    clean_build='--clean'
  fi
  if [[ "$WORKSPACE" ]]; then
    workspace="--workspace $WORKSPACE"
  fi
  bundle exec fastlane gym build \
    $workspace \
    --scheme "$scheme" \
    $clean_build

  msg "Submitting to iTunes Connect"
  bundle exec fastlane deliver run \
    --app_identifier "$BUNDLE_IDENTIFIER" \
    --username "$ITC_USER" \
    --force true

  comp_deinit
}
