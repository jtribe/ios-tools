# iOS Scripting Tools

These tools handle several common iOS scripting tasks, such as developer environment setup, CI and
deployment to iTunes Connect.

They are implemented using a simple scripting framework in `bin/execute.sh` which provides access
to the functions in `bin/components`.

- Run `bin/setup.sh` to setup your dev environment
- Run `bin/execute.sh` for usage
- Run `bin/update.sh` to update the project dependencies
- Run `bin/git-update.sh` to pull changes from upstream and update the project dependencies

To add new capabilities refer to `script_usage()`, `parse_params()` and `run_task()` in `execute.sh`
and the various components.

## Prerequisites

- Xcode
- Bundler: `sudo gem install bundler`

## Installation

These steps only need to be performed once, developers simply need to run `./bin/execute.sh setup`.

```bash
sudo gem install gemrat
git submodule add git@github.com:jtribe/ios-tools.git bin
touch Gemfile .config.sh
gemrat xcpretty gym deliver match
bundle install
```

- Use Xcode to add a Build Phase called "Set Bundle Version" that runs the script `bin/xcode/bundle-version.sh`
  (see [below](#bundle-versions) for more info)
- Add `.config.sh` and a `config/` directory to your project (see [below](#configsh) for more info)

## Developer Setup

```bash
./bin/execute.sh setup
```

## CI Setup

Add the following environment variables in the CI setup:

- `MATCH_PASSWORD`: the passphrase for the [match](https://github.com/fastlane/match) repository
- `FASTLANE_PASSWORD`: the password for the iTunes Connect Account (for the `ITC_USER` specified in `.config.sh`)

### `.config.sh`

This file defines several variables that are used in these scripts.

```sh
export PROJECT="MyAwesomeProject"
export WORKSPACE="$PROJECT.xcworkspace" # Leave this empty if a workspace is not required
export SCHEME="$PROJECT"
export TEST_SCHEME="${PROJECT}Tests"
export UI_TEST_SCHEME="${PROJECT}UITests"
export TEST_DESTINATION="platform=iOS Simulator,name=iPhone 6,OS=9.0"

export BUNDLE_IDENTIFIER="com.foobar.MyAwesomeProject"
export ITC_USER="user@domain.com" # iTunes Connect User
```

### ?? `config/` directory

The following files should be created in the `config/` directory. The certificates The `.p12` files can be exported from your Keychain.

- _iOS Developer_ certificate and private key in `developer.cer` and `developer.p12`
- _iOS Distribution_ certificate and private key in `distribution.cer` and `distribution.p12`
- All required provisioning profiles should be added to the `config/profiles/` directory

### CircleCI Configuration

A typical `circle.yml` setup is as follows.

```yaml
machine:
  xcode:
    version: '7.2'
dependencies:
  pre:
    - ./bin/execute.sh ci-setup
    - security find-identity -p codesigning
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

## Bundle Versions

The Bundle Versions are based on git commits (see `xcode/bundle-version.sh`). You can work out the
commit for a Bundle Version by entering it into the following command:

```bash
git log `git rev-list origin/master | awk "NR == $bundle_version"`
```
