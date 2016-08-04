# iOS Scripting Tools

These tools handle several common iOS scripting tasks, such as:

- Developer environment setup
- CI
- Certificates and provisioning profiles (using Fastlane [match](https://github.com/fastlane/match))
- Deployment to iTunes Connect.

Most functions are accessed using a simple scripting framework in `bin/execute.sh` that provides access
to the functions in `bin/components`.

- Run `bin/execute.sh` for usage
- Run `bin/execute.sh setup` to setup your dev environment
- Run `bin/update.sh` to update the project dependencies
- Run `bin/git-update.sh` to pull changes from upstream and update the project dependencies

To add new capabilities refer to `script_usage()`, `parse_params()` and `run_task()` in `execute.sh`
and the various components.

---

## Prerequisites

- Xcode
- `gem install bundler gemrat`

If you're using Mac OS 10.11 "El Capitan" you may want to install Ruby using Homebrew to avoid
permissions issues with `/usr/bin`. You can do this using `brew install ruby` (you might need to
open a new shell session too).

If you're using rvm to manage ruby versions and fish shell instead of bash, you can get rvm support under fish by following [these instructions](https://rvm.io/integration/fish).

---

## Installation

These steps only need to be performed once, developers simply need to run `bin/execute.sh setup`.

```sh
git submodule add git@github.com:jtribe/ios-tools.git bin
touch .config.sh
bundle init
gemrat --pessimistic cocoapods xcpretty gym deliver match
```

---

## `.config.sh`

This file defines several variables that are used in these scripts.

```sh
export PROJECT="MyAwesomeProject" # the name of the .xcodeproj, not the repo
# export WORKSPACE="$PROJECT.xcworkspace" # Comment this out for no workspace.
export SCHEME="$PROJECT"
export TEST_SCHEME="${PROJECT}Tests"
export UI_TEST_SCHEME="${PROJECT}UITests" # Comment this out for no UI tests
export TEST_DESTINATION="platform=iOS Simulator,name=iPhone 6,OS=9.2"

export BUNDLE_IDENTIFIER="com.foobar.MyAwesomeProject"
export ITC_USER="ios@jtribe.com.au" # iTunes Connect User

export CARTHAGE_OPTS="--platform iOS" # Options for Carthage commands
```

_Special Note: It is absolutely essential that the `BUNDLE_IDENTIFIER` matches exactly what's in iTunes Connect and Xcode._

You will need to share each of these schemes in Xcode so that these are available on CI. In Xcode, go to _Manage Schemes_ and tick the _Shared_ checkbox for each.

---

## Developer Setup

```bash
bin/execute.sh setup
```

---

## Carthage Setup

If you are using Carthage, we _**do not**_ build the _Carthage_ modules on CI. Instead, we use Carthage as per usual and check in the built frameworks to Git. The [.gitignore file](https://github.com/jtribe/ios-tools/blob/master/.gitignore) file excludes the _Carthage/Checkouts/_ folder, but includes the compiled binaries.

---

## CircleCI Configuration

Add a `circle.yml` file to the root directory of the project. A typical `circle.yml` setup is as
follows.

The SSH Key will never change.

```yaml
machine:
  xcode:
    version: '7.3' # 7.3 is correct as of May 12 2016
checkout:
  post:
    - git submodule update --init
dependencies:
  # we override dependencies because CircleCI doesn't use `bundle exec` when calling `pod install`
  override:
    - bin/execute.sh pods
test:
  override:
    - bin/execute.sh test
    - mv build/reports/* $CIRCLE_TEST_REPORTS
deployment:
  itunes_connect:
    branch: release
    commands:
      # add bitbucket.org to known_hosts so that match can download the certificates repo
      - echo -e '\nbitbucket.org ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==' >> ~/.ssh/known_hosts
      - bin/execute.sh itunes-connect
```

---

## Enabling Builds in CI

After you've done the above step, an admin of the Repo needs to go into CircleCI and allow builds for the project. If you're not an admin, stop doing what you're doing and procure someone who can do this for you.

In order for CircleCI to be able to fetch this repo (ios-tools) as a submodule, you will need to [add a "user
key" to the Project Settings](https://circleci.com/docs/external-resources).

---

## Code Signing and Continuous Deployment

See detailed instructions [here](docs/code-signing-and-cd.md). Be aware that this process often
needs to be updated because of changes in Xcode and iTunes Connect.

## Bundle Versions

The Bundle Versions are based on git commits (see `xcode/bundle-version.sh`). You can work out the
commit for a Bundle Version by entering it into the following command:

```bash
git log `git rev-list origin/master | awk "NR == $bundle_version"`
```

---

## Troubleshooting

- If you get a message from match saying _Could not create another certificate, reached the maximum number of available certificates._ see this [StackOverflow answer](http://stackoverflow.com/a/26780411/822249)
- If CircleCI is failing, and you **are using Carthage** then make sure your frameworks are being committed to Git as detailed above.
  - Also make sure you have added the Carthage Copy Frameworks run-script Build Phase in Xcode.
  - Also make sure that each Framework has its minimum deployment target set to **9.0** for Xcode 7.3.
- If you **are not using Carthage** then make sure `Compiler Optimisation` is set to `None` in Xcode for both Release and Debug configurations.


### Upgrading CocoaPods in a legacy project

If you have an older project that isn't using CocoaPods 1.0 and you want/need to update it, these steps should help:

1. Make sure you're using a recent ruby version (2.3.x for now) - if you don't have it you can run `brew install ruby` or for a specific/multiple version(s) `brew install rvm`, `rvm install 2.3.1`, `rvm use 2.3.1`
2. You'll need to set which new versions of gems/pods you want using `bundle exec gem update [gemname]` or `bundle exec update [podname]` - specify a `gemname` or `podname` if there is a single gem/pod you wish to update, or leave off to update all to the latest allowed by their respective Gemfile/Podfile.
3. Run `bun/execute.sh setup` which installs gems, runs match, and installs pods (among other things)
4. If you have problems building/linking clean your project (shift-cmd-K) and clean the output folder (shift-opt-cmd-K). The latter can correct linker issues regarding arm7 architecture and other weird problems where you can build for the simulator but not for a device.

Note: If you've upgraded CocoaPods to a version that changes its integration with XCode (ie. 0.39 to 1.0) then you might need to run `bundle exec pod deintegrate` then `bundle exec pod install` before opening and building your project. 
