# iOS Scripting Tools

These tools handle several common iOS scripting tasks, such as:

- Developer environment setup
- CI
- Certificates and provisioning profiles (using Fastlane [match](https://github.com/fastlane/match))
- Deployment to iTunes Connect.

Most functions are accessed using a simple scripting framework in `bin/execute.sh` that provides access
to the functions in `bin/components`.

- Run `bin/setup.sh` to setup your dev environment
- Run `bin/execute.sh` for usage
- Run `bin/update.sh` to update the project dependencies
- Run `bin/git-update.sh` to pull changes from upstream and update the project dependencies

To add new capabilities refer to `script_usage()`, `parse_params()` and `run_task()` in `execute.sh`
and the various components.

## Prerequisites

- Xcode
- `gem install bundler gemrat`

If you're using Mac OS 10.11 "El Capitan" you may want to install Ruby using Homebrew to avoid
permissions issues with `/usr/bin`. You can do this using `brew install ruby` (you might need to
open a new shell session too).

## Installation

These steps only need to be performed once, developers simply need to run `./bin/execute.sh setup`.

```sh
git submodule add git@github.com:jtribe/ios-tools.git bin
touch .config.sh
bundle init
gemrat --pessimistic cocoapods xcpretty gym deliver match
```

In order to run on their devices before the provisioning profiles have been created:

- Open the project settings in Xcode
- In the _General_ tab select _None_ in the Team dropdown
- In _Build Settings > Code Signing_ select _Don't Code Sign_ option for _Debug_ and _iOS Developer_ for _Any iOS SDK_

### `.config.sh`

This file defines several variables that are used in these scripts.

```sh
export PROJECT="MyAwesomeProject"
# export WORKSPACE="$PROJECT.xcworkspace" # Comment this out for no workspace
export SCHEME="$PROJECT"
export TEST_SCHEME="${PROJECT}Tests"
export UI_TEST_SCHEME="${PROJECT}UITests" # Comment this out for no UI tests
export TEST_DESTINATION="platform=iOS Simulator,name=iPhone 6,OS=9.2"

export BUNDLE_IDENTIFIER="com.foobar.MyAwesomeProject"
export ITC_USER="user@domain.com" # iTunes Connect User
```

You will need to share the schemes for `$SCHEME` and `$UI_TEST_SCHEME` (if used) in Xcode so that
these are available on CI. In Xcode, go to _Manage Schemes_ and select _Shared_ for each.

## Developer Setup

```bash
./bin/execute.sh setup
```

## CircleCI Configuration

Add a `circle.yml` file to the root directory of the project. A typical `circle.yml` setup is as
follows.

```yaml
machine:
  xcode:
    version: '7.2'
checkout:
  post:
    - git submodule update --init
dependencies:
  override:
    - ./bin/execute.sh pods
    - ./bin/execute.sh carthage
test:
  override:
    - ./bin/execute.sh test
    - mv build/reports/* $CIRCLE_TEST_REPORTS
deployment:
  itunes_connect:
    branch: release
    commands:
      # add bitbucket.org to known_hosts so that match can download the certificates repo
      - echo -e '\nbitbucket.org ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==' >> ~/.ssh/known_hosts
      - ./bin/execute.sh itunes-connect
```

Now go to CircleCI and enable builds for the project. In order for CircleCI to be able to fetch this
repo (ios-tools) as a submodule, you will need to [add a "user key" to the Project
Settings](https://circleci.com/docs/external-resources).

## Code Signing and Continuous Deployment

We use the Fastlane tool [match](https://github.com/fastlane/match) to handle provisioning profiles
and code signing. See the [usage docs](https://github.com/fastlane/match#usage) for more information.

> If you're not familiar with this tool then visit [codesigning.guide](https://codesigning.guide/)
to understand the rationale behind this approach.

### Configure Apple Services

- Ensure that an Apple ID has been created that will be used for the app
	- If it will be released by jtribe then use `armin@jtribe.com.au`
	- Otherwise the client will need to set up the following services and send us the Apple ID and password:
		- https://developer.apple.com/membercenter/
			- Enrol in the _Apple Developer Program_ (this costs $149 per year)
		- https://itunesconnect.apple.com/
	- Record the Apple ID in the project README.md
	  ([example](https://github.com/jtribe/whispir-ios/blob/master/README.md)) and store the password in
		our password tool using a Login item named e.g. "BWF Apple ID"
  - The iTunes Connect user will need to have _App Manager_ permission
- Create the App in Dev Center and iTunes Connect
	- You can either use the Fastlane `produce` tool or do this manually through the browser. If you use `produce` then
    you'll need to specify `--company_name` if it's the first app for the Apple ID.

### Create Certificates and Provisioning Profiles

- Create a private Git repository (typically using our Bitbucket account) for storing the encrypted certificates and provisioning profiles, there should be one per client
  - Add an SSH key that can be used by CI to access the repository:
    ```
    ssh-keygen -f temp-key
    cat temp.pub | pbcopy # add this to BitBucket in project settings > Deployment keys
    cat temp | pbcopy # add this to CircleCi in project settings > SSH Permissions (hostname: `bitbucket.org`)
    ```
- `bundle exec match init` to set up the certificates repo and create the `Matchfile`
  - This will ask you for the URL to the Git repository for the certs - make sure that you use the SSH URL for the repo so that we can provide CI with an SSH key to download it
- Edit the created `Matchfile` to set `username` to the Apple ID and `app_identifier` to the Bundle Identifier
  - These should match the values for `ITC_USER` and `BUNDLE_IDENTIFIER` in `.config.sh`
- `bundle exec match development` to create the Debug certificate
	- This will add devices to the provisioning profile, however this fails if none exist. So [add your
    device](#adding-devices) to the Dev Center, but you can skip adding it to the provisioning profile
		because `bundle exec match development` will do this
  - Store the passphrase in our password tool using a Password item named e.g. "BWF Certificates Passphrase"
- `bundle exec match appstore` to create the Distribution certificate

### Configure the Xcode Project

- You might need to restart Xcode (seriously!) or run `bundle exec match development` and `bundle exec match appstore` again
- In Xcode
	- Go to Preferences > Accounts and add an account using the Apple ID (this is only required on setup)
	- Go to the General > Identity in your project's main target and select the Team
    - The Version must be a period-separated list of at most three non-negative integers
  - Go to Build Settings > Build Phases and add a Build Phase called "Set Bundle Version" that runs
    the script `bin/xcode/bundle-version.sh` (see [below](#bundle-versions) for more info)
  - Go to Build Settings > Code Signing
  	- Set the Provisioning Profiles for Debug and Release to the created Development and AppStore profiles
  	- Set the Code Signing Identity for Debug and Release to the identities from the selected profiles

#### CI Setup

- Go to
Add the following environment variables in the CI setup:

- `MATCH_PASSWORD`: the passphrase for the [match](https://github.com/fastlane/match) repository
- `FASTLANE_PASSWORD`: the password for the iTunes Connect Account (for the `ITC_USER` specified in `.config.sh`)

### Adding Devices

- Login to the Developer Center
- Go to Devices > All and click the add button
- You can get the UDID of your device using Xcode by plugging it in and going to Window > Devices
- If the development provisioning profile has already been created, then you'll need to add this
	device to it using `match development --force`

## Bundle Versions

The Bundle Versions are based on git commits (see `xcode/bundle-version.sh`). You can work out the
commit for a Bundle Version by entering it into the following command:

```bash
git log `git rev-list origin/master | awk "NR == $bundle_version"`
```
