# iOS Scripting Tools

These tools provide scripts for several common iOS scripting tasks. They are implemented using a
basic scripting framework in `bin/execute.sh`, which provides access the functions in
`bin/components`.

Run `bin/execute.sh` for usage.

To add new capabilities refer to `script_usage()`, `parse_params()` and `run_task()` in `execute.sh`
and the various components.

## Prerequisites

- Xcode 7.x Command Line Tools
- iOS Simulator 9.0
- xcpretty - this will typically be installed from the project's Gemfile

Add a build step called "Set Bundle Version" that runs the script `bin/xcode/bundle-version.sh`

The Bundle Versions are based on git commits (see `xcode/bundle-version.sh`). You can work out the
commit for a Bundle Version by entering it into the following command:

```bash
git log `git rev-list origin/master | awk "NR == $bundle_version"`
```

## CI Setup

Add `.config.sh` and a `config/` directory to your project, see below for details.

Add the following environment variables in the CI setup:

- `DEV_KEY_PASSWORD` and `DIST_KEY_PASSWORD`: the password (if any) for your private keys
- `ITC_PASSWORD`: The password for the iTunes Connect Account (for the `ITC_USER` specified in `.config.sh`)

### `.config.sh`

This file defines several variables that are used in these scripts.

```sh
export PROJECT="MyAwesomeProject"
export WORKSPACE="$PROJECT.xcworkspace"
export TEST_SCHEME="${PROJECT}Tests"
export UI_TEST_SCHEME="${PROJECT}UITests"
export DESTINATION="platform=iOS Simulator,name=iPhone 6,OS=9.0"
```

### `config/` directory

The following files should be created in the `config/` directory. The `.p12` files can be exported from your Keychain.

- _iOS Developer_ certificate and private key in `developer.cer` and `developer.p12`
- _iOS Distribution_ certificate and private key in `distribution.cer` and `distribution.p12`
- All required provisioning profiles should be added to the `config/profiles/` directory

### CircleCI Configuration

A typical `circle.yml` setup is as follows.

```yaml
machine:
  xcode:
    version: '7.0'
dependencies:
  pre:
    - curl -L -O https://github.com/Carthage/Carthage/releases/download/0.9.4/Carthage.pkg
    - sudo installer -pkg Carthage.pkg -target /
    - ./bin/execute.sh ci-setup
    - security find-identity -p codesigning
    - ./bin/execute.sh carthage
  cache_directories:
    - Carthage
test:
  override:
    - ./bin/execute.sh test
deployment:
  itunes_connect:
    branch: release
    commands:
      - git fetch --unshallow # this is required for bundle-version.sh because CircleCI uses a shallow clone
      - ./bin/execute.sh itunes-connect
```

### Travis CI setup

A typical `.travis.yml` setup is as follows.

```yaml
osx_image: xcode7
language: objective-c
xcode_workspace: nxgen-ios.xcworkspace
xcode_scheme: nxgen-iosTests
before_install:
  - curl -L -O https://github.com/Carthage/Carthage/releases/download/0.9.3/Carthage.pkg
  - sudo installer -pkg Carthage.pkg -target /
before_script:
  - ./bin/execute.sh ci-setup
  - security find-identity -p codesigning
  - ./bin/execute.sh carthage
script:
  - ./bin/execute.sh unit-tests
```
