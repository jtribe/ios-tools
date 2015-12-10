function ci_setup() {
  comp_init 'circleci'

  keychain="$PROJECT-build.keychain"
  keychain_path=~/Library/Keychains/$keychain
  keychain_password="password"
  profiles=~/Library/MobileDevice/Provisioning\ Profiles

  msg "Creating keychain '$keychain_path'"
  if [[ -f $keychain_path ]]; then
    security delete-keychain "$keychain"
  fi
  security create-keychain -p "$keychain_password" "$keychain"
  apple_wwdr="./config/apple_wwdr.cer"
  curl 'https://developer.apple.com/certificationauthority/AppleWWDRCA.cer' > "$apple_wwdr"
  security import "$apple_wwdr" -k "$keychain_path" -T /usr/bin/codesign
  security import ./config/developer.cer -k "$keychain_path" -T /usr/bin/codesign
  security import ./config/developer.p12 -k "$keychain_path" -P "$DEV_KEY_PASSWORD" -T /usr/bin/codesign
  security import ./config/distribution.cer -k "$keychain_path" -T /usr/bin/codesign
  security import ./config/distribution.p12 -k "$keychain_path" -P "$DIST_KEY_PASSWORD" -T /usr/bin/codesign
  security list-keychain -s ~/Library/Keychains/login.keychain "$keychain_path"
  security unlock-keychain -p "$keychain_password" "$keychain_path"

  msg 'Installing provisioning profiles'
  mkdir -p "$profiles"
  cp ./config/profiles/* "$profiles/"
}
