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

> If you want to be able to run on devices before the provisioning profiles have been created:

> - Open the project settings in Xcode
> - In the _General_ tab select _None_ in the Team dropdown
> - In _Build Settings > Code Signing_ select _Don't Code Sign_ option for _Debug_ and _iOS Developer_ for _Any iOS SDK_

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
export ITC_USER="ios@jtribe.com.au" # iTunes Connect User
```

You will need to share each of these schemes in Xcode so that
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
  # we override dependencies because CircleCI doesn't use `bundle exec` when calling `pod install`
  override:
    - bundle install
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

Now an admin of the repo needs to go to CircleCI and enable builds for the project. In order for
CircleCI to be able to fetch this repo (ios-tools) as a submodule, you will need to [add a "user
key" to the Project Settings](https://circleci.com/docs/external-resources).

## Code Signing and Continuous Deployment

We use the Fastlane tool [match](https://github.com/fastlane/match) to handle provisioning profiles
and code signing. See the [usage docs](https://github.com/fastlane/match#usage) for more information.

> If you're not familiar with this tool then visit [codesigning.guide](https://codesigning.guide/)
to understand the rationale behind this approach.

### Configure Apple Services

The following services will need to be set up:

- [Developer Member Center](https://developer.apple.com/membercenter/)
	- Enrol in the _Apple Developer Program_ (this costs $149 per year)
- [iTunes Connect](https://itunesconnect.apple.com/)

Invitations should be sent to `ios@jtribe.com.au` for both of these services:

- The iTunes Connect user should have at least _App Manager_ permissions
- The Developer Center user should have at least _Member_ permissions

Once the invitations have been accepted and `ios@jtribe.com.au` has access to these services, go to
Xcode > Preferences > Accounts and add this account (if it isn't already there), you should see the
team for this project now displayed in the list of teams. Now go to General > Identity in your
project's main target and select this team.

Create the App in Dev Center and iTunes Connect. You can either do this manually through the browser
or use the Fastlane `produce` tool (you'll need to specify `--company_name` if it's
the first app for the Apple ID).

### Create Certificates and Provisioning Profiles

You will need to have a _certificates repository_ for storing the encrypted certificates and
provisioning profiles. There should be one of these per client, and it's separate to the repo for
the project. If one doesn't already exist then you should create one, typically under the jtribe
Bitbucket team.

- `bundle exec match init` to set up the certificates repo and create the `Matchfile`
  - This will ask you for the URL to the certificates repository. Make sure that you use the SSH URL
    for the repo so that we can provide CI with an SSH key to download it
- Edit the created `Matchfile`
  - Set `username` to `ios@jtribe.com.au` and `app_identifier` to the Bundle Identifier. These
    should match the values for `ITC_USER` and `BUNDLE_IDENTIFIER` in `.config.sh`
    - Be sure to remove the `#` before `username` and `app_identifier` to un-comment these lines
  - Enter the `team_id` that you selected if you were prompted by `match` to select a team
    e.g. `team_id "X12345678" # Foobar Widgets Inc.`
- `bundle exec match development` to create the Debug certificate
	- This will add devices to the provisioning profile, however this fails if none exist. So [add your
    device](#adding-devices) to the Dev Center, but you can skip adding it to the provisioning profile
		because `bundle exec match development` will do this
  - Store the passphrase in our password tool using a Password item named e.g. "BWF Certificates Passphrase"
- `bundle exec match appstore` to create the Distribution certificate

### Configure the Xcode Project

- You might need to restart Xcode (seriously!) or run `bundle exec match development` and `bundle exec match appstore` again
- In Xcode
	- Go to the General tab and ensure that Version is "a period-separated list of at most three non-negative integers"
  - Go to Build Settings > Build Phases and add a Build Phase called "Set Bundle Version" that runs
    the script `bin/xcode/bundle-version.sh` (see [below](#bundle-versions) for more info)
  - Go to Build Settings > Code Signing
  	- Set the Provisioning Profiles:
      - Debug: `match Development {{bundle ID}}`
      - Release: `match AppStore {{bundle ID}}`
  	- Set the Code Signing Identities:
      - Debug: `iPhone Developer`
      - Release: `iOS Distribution`

### CI Setup

Add the following environment variables in the CI setup:

- `MATCH_PASSWORD`: the passphrase for the [match](https://github.com/fastlane/match) repository
- `FASTLANE_PASSWORD`: the password for the iTunes Connect Account (for the `ITC_USER` specified in `.config.sh`)

Create an SSH key pair that can be used by CI to access the certificates repository:

```sh
# generate a new SSH key pair (no passphrase is required)
ssh-keygen -f temp-key
# add the public key to BitBucket in the project settings > Deployment keys
cat temp-key.pub
# add the private key to CircleCI (hostname `bitbucket.org`) in the project settings > SSH Permissions
cat temp-key
rm temp-key temp-key.pub
```

### Adding Devices

- Login to the Developer Center
- Go to Devices > All and click the add button
- You can get the UDID of your device using Xcode by plugging it in and going to Window > Devices
- If the development provisioning profile has already been created, then you'll need to add this
	device to it using `match development --force_for_new_devices`

## Bundle Versions

The Bundle Versions are based on git commits (see `xcode/bundle-version.sh`). You can work out the
commit for a Bundle Version by entering it into the following command:

```bash
git log `git rev-list origin/master | awk "NR == $bundle_version"`
```
