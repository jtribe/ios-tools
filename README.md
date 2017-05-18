# iOS Tools


## Summary
iOS Tools is a set of scripts designed to **HELP** streamline common and tedious processes in iOS development.
Specifically, it assists with the following...
- Creating & Managing Codesigning
- Setup of Pods & Carthage Frameworks
- Deploying to Circle CI (Continuous Development)
- Deploying to iTunes Connect

These scripts are added as a git submodule to the iOS project.

---

## Prerequisites
- Xcode Command Line Tools (Can be installed using `xcode-select --install`)
- Ruby V2.3 (Suggested install with Homebrew)
- Gemrat (Can be installed using `gem install bundler gemrat`)

(If you're using rvm to manage ruby versions and fish shell instead of bash, you can get rvm support under fish 
by following [these instructions](https://rvm.io/integration/fish).)

---

## Installation

### Adding The `ios-tools` Scripts
The following steps need to be performed once to setup the *ios-tools* scripts within your project.
Navigate to your projects directory in terminal and add perform the following commands.

```sh
git submodule add git@github.com:jtribe/ios-tools.git bin
touch .config.sh
bundle init
```

This will result in a "bin" folder appearing, which will contain the shell files to be run in order to perform 
common tasks.

### Adding gems

`ios-tools` requires gym 2.x, deliver 2,x and match 1.x (these all require fastlane 2.x)

To create a `Gemfile` use `gemrat`:

```
gemrat --pessimistic cocoapods xcpretty gym deliver match
```

then edit the `Gemfile` to remove all the patch versions (so `1.2.3` becomes `1.2`) so that we will receive new 
minor versions (at least for `gym`, `deliver` and `match`). Then run:

```
bundle update
```

(n.b This will *NOT* setup codesigning for the project. Please refer to the "Codesigning" section of this ReadMe 
for its setup information.)

### Configuring Files

The file `.config.sh`, which should be in the project root directory, defines several variables that are used in 
the `ios-tools` scripts.
Open it up and set the variables to the appropriate values. It will look something like the following...

```sh
export PROJECT="MyAwesomeProject" # the name of the .xcodeproj, not the repo
# export WORKSPACE="$PROJECT.xcworkspace" # Comment this out for no workspace.
export SCHEME_BASE="${PROJECT}"
export PROD_SCHEME="${SCHEME_BASE}-PROD"
export UNIT_TEST_SCHEME="${SCHEME_BASE}-DEV"
export UI_TEST_SCHEME="${SCHEME_BASE}-UITests" # Comment this out for no UI tests
export TEST_DESTINATION="platform=iOS Simulator,name=iPhone 6s Plus,OS=10.1"
export SIMULATOR_NAME="iPhone 6s Plus (10.1)" # Must match $TEST_DESTINATION device/OS version

export BUNDLE_IDENTIFIER="com.foobar.MyAwesomeProject"
export ITC_USER="ios@jtribe.com.au" # iTunes Connect User

export CARTHAGE_OPTS="--platform iOS" # Options for Carthage commands
```

Note: `BUNDLE_IDENTIFIER` **Must Match** that used in xcode and on iTunes connect
(To use Circle-CI,these schemes must be shared. In Xcode, go to _Manage Schemes_ and tick the _Shared_ checkbox 
for each.)

---

## Codesigning

Codesigning is handled using the tool `match`, a product of `fastlane`. The tool `match` works by creating all of 
the necessary code signing files needed for development, then syncing them into one private git repository. By 
doing this, all developers on a team can use and access the same profiles and certificates. It also includes 
commands to make updating these files quick and easy.

Read the [Code Signing Guide](https://codesigning.guide/) for an understanding of the rationale behind `match`.

#### 1. Create App ID
To begin, an `App ID` for the project must be created in the iOS Developer Member Centre. To do this
1. Login to the member centre using the teams apple account.
2. Navigate to the "Certificates, Identifiers & Profiles" section
3. Select `App IDs` in the left side menu, then select the "+" button, in the top right
(The App ID used here must match your project bundle ID, as well as any references you make to the App ID in 
configuration files)

#### 2. Login to Team in Xcode
Once an App ID is set up in the developer centre, navigate to XCode and make sure you are signed into your Team's 
Apple ID. You can check if you have already done this by navigating to Xcode and selecting 
`Xcode -> Preferenes -> Accounts` and checking if your team appearing under the subheading "Apple IDs". if it 
doesn't, add it, by selecting the "+" button and entering the authentication details.

#### 3. Create/Select Private Certificates Repository
If this is the first app created this client/team, you will need to create a new certificates repository. This 
is where your code signing documents will be securely kept. One repository should be used for all apps for a 
given client, so if an app exists for this client/team re-use the existing one and skip this step. Navigate to 
the site where you wish to host this repository (github is now the preferred host, not bitbucket, since we have 
unlimited private repos now) and create an empty repository. The recommended name is "{CLIENT NAME}-certificates".

#### 4. Create Everything Using `match`

- Run the following: `bundle exec match init` (Provide private certificates SSH URL when prompted). There is no 
harm running this command with an existing certificate repo, it won't overwrite your existing certificates. 
However you could probably just copy the `Matchfile` from an existing project instead.
- Create a file named `Appfile` and add the following...

```
app_identifier "com.example.appname"    # This is your BUNDLE_IDENTIFIER
apple_id "example@example.com.au"
team_id "12A345B6CD"                    # The Team ID as displayed in the Member Center - Login and click MEMBERSHIP in the sidebar.
itc_team_id "123456789"                 # itc_team_id can ONLY BE FOUND when CircleCI fails to login to iTunes Connect the first time. You'll see a list of teams available, and next to the name in brackets is a numerical value. Take the value you want, and use it for itc_team_id.
```
- Run `bundle exec fastlane match development` to create/store/retrieve development certificates and profiles.
- Run `bundle exec fastlane match appstore` to create/store/retrieve distribution certificates and profiles.

#### 5. More Information
If you have issues and require further reading, try [here](docs/code-signing-and-cd.md).

---

## Pods & Carthage

If using **CocoaPods**, the standard `bin/execute.sh setup` will handle the installation of pods specified in the 
Podfile. Note that in Circle CI builds we rely on Circle's inferred dependency steps to take advantage of their 
caching of the pod master spec repo, hence in `circle.yml` you will see the `bin/execute.sh setup --no-pods` 
which skips `bundle install` and `bundle exec pod install` commands.

If using **Carthage**, the standard `bin/execute.sh setup` will handle the download and building of frameworks 
specified in the Cartfile. They will still need to be added to the Xcode project manually, if not yet done so. If the `/Carthage` directory already exists (ie. was cached by CI) a copy of the `Cartfile.resolved` stored in `/Carthage` will detected if the `Cartfile` has changed and only build Carthage dependencies if they're out of date or missing.

NOTE: When updating Carthage libraries and rebuilding, it is best practise to keep this in a separate commit/PR to keep the noise out of code reviews.

---

## Circle-CI Configuration

### Add `circle.yml` File

Add a `circle.yml` file to the root directory of the project. A typical `circle.yml` setup is as
follows.


```yaml

machine:
  xcode:
    version: '8.2'
checkout:
  post:
    # download ios-tools 
    - git submodule update --init
dependencies:
  post:
    # run match after Circle runs bundler and pods
    - bin/execute.sh setup --no-pods
  cache_directories:
    - "Carthage"
test:
  override:
    - bin/execute.sh test --restart-simulator
    - mv build/reports/* $CIRCLE_TEST_REPORTS
    - cp -r $CIRCLE_TEST_REPORTS $CIRCLE_ARTIFACTS
    - find /Users/distiller/Library/Developer/Xcode/DerivedData/MyProject-* -name "*.log" -exec cp '{}' $CIRCLE_ARTIFACTS \;
    - cp /Users/distiller/Library/Logs/CoreSimulator/CoreSimulator.log $CIRCLE_ARTIFACTS
deployment:
  itunes_connect_alpha:
    branch: master
    commands:
      - bin/execute.sh itunes-connect --scheme MyProject-ALPHA
  itunes_connect_prod:
    branch: release/beta
    commands:
     - bin/execute.sh itunes-connect --scheme MyProject-PROD
```

Replacing `MyProject` above with your project name.

n.b. If you are working on an existing project that still use bitbucket for the certificate repository, you will 
need to add SSH keys _before_ you run `bin/execute.sh setup` in the post-checkout steps:

```yaml
- echo -e '\nbitbucket.org ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==' >> ~/.ssh/known_hosts
```

### Enable Builds On Circle CI

After you've done the above step, an admin of the repository will need to go into Circle-CI and allow builds for 
the project.

In order for CircleCI to be able to fetch this repository (ios-tools) and access the certificate repo as a 
submodule, you will need to [add a "user
key" to the Project Settings](https://circleci.com/docs/external-resources). Delete the existing deploy key.


## Usage
Most functions are accessed using a simple scripting framework in `bin/execute.sh` that provides access
to the functions in `bin/components`.

- Run `bin/execute.sh` for usage
- Run `bin/execute.sh setup` to setup your dev environment
- Run `bin/update.sh` to update the project dependencies
- Run `bin/git-update.sh` to pull changes from upstream and update the project dependencies
- Run `bin/execute.sh test` to run unit/UI tests

Once all areas are setup, developers *should* simply have to run `bin/execute.sh setup` after checking out the 
project to have ios-tools setup and create everything. 

---

## Bundle Versions/Build Numbers

The Build Numbers are based on git commits (see `xcode/bundle-version.sh`). You can work out the
commit for a Build Number for a production or beta build by entering it into the following command,
substituting `XXXX` for the build number:

```bash
git rev-list origin/release/beta | head -XXXX | tail -1

```

and for an alpha build:

```bash
git rev-list origin/master | head -XXXX | tail -1

```

---

### Upgrading ios-tools

```bash
cd bin
git fetch
git diff origin/master
# review the changes and update your project as required
git co master
git pull
cd ..
```

Then follow the steps for [adding gems](#Adding-gems).

## Troubleshooting

- If you get an error saying `Unable to satisfy the following requirements ... Note as of Cocoapods 1.0 pod repo update does not happen on pod install by default` when running `bin/execute.sh setup` then you need to update your cocoapods master spec repo by running `bundle exec pod repo update` then re-running `bin/execute.sh setup`. 
- Apple change things all the time. If you're having trouble deploying to the App Store then the first thing to do is
make sure that we're using the latest versions of the Fastlane tools by [updating gems](#Adding-gems).
- If you are having issues with codesigning and debugging on a device, follow these steps:
  1. Make sure the device is added to the developer portal and that it is then also added to the provisioning profile.
  2. Run `bundle exec match development --force_for_new_devices`. 
  3. [Check your Xcode setup](https://docs.fastlane.tools/codesigning/xcode-project/#xcode-7-and-lower) which is different
    for Xcode 8.
  4. Make sure you only have 1 developer certificate installed in Xcode. Go to Preferences, then Account, select the
  `ios@jtribe.com.au` account then click `View Details`. Delete all but the most recent development certificate for the
  team you are working with.
  5. In the project settings, go to the `Code Signing` section and make sure the Provisioning Profile is set to `match Development <your_bundle_id>` and `match AppStore <your_bundle_id>` for both `Debug` and `Release` respectively. 
  6. Under Code Signing Identity, choose the `iPhone Developer: <your_team> (<team_id>)` identity for `Debug` and `iPhone Distribution: <your_team> (<team_id>)` for `Release`.
  7. Repeat steps `v.` and `vi.` for each app and test target in the workspace.
  8. Build and run!
- If you get a message saying `FastlaneCore::Interface::FastlaneCrash: [!] No code signing identity found and can not create a new one because you enabled 'readonly'` when running `bin/execute.sh setup` it is because match needs to create a new certificate or provisioning profile, which the standard setup script is unable to do. Run `bundle exec match development` or `bundle exec match appstore`, depending on which you want to create (there's no harm in just running both to be sure).
- If you get a message from match saying _Could not create another certificate, reached the maximum number of 
available certificates._ it is probably because you are creating a new certificate repository for multiple apps 
for the same client/team. The best resolution is probably to change over to using the existing repo and
recreating your provisioning profiles, but if you want to manually import your development certificate into a new
match repository see [these steps](docs/manual-match.md).
- If CircleCI is failing, and you **are using Carthage** then make sure your frameworks are being committed to 
Git as detailed above.
  - Also make sure you have added the Carthage Copy Frameworks run-script Build Phase in Xcode.
  - Also make sure that each Framework has its minimum deployment target set to **9.0** for Xcode 7.3.
- If you **are not using Carthage** then make sure `Compiler Optimisation` is set to `None` in Xcode for both 
Release and Debug configurations.
- If you're revisiting an **OLD** project, and nothing works _whatsoever_ it's because you'll need to `git 
submodule update` and `cd` into the directory then `git pull` from `master`.

### Upgrading CocoaPods in a legacy project

If you have an older project that isn't using CocoaPods 1.0 and you want/need to update it, these steps should 
help:

1. Make sure you're using a recent ruby version (2.3.x for now) - if you don't have it you can run `brew install 
ruby` or for a specific/multiple version(s) `brew install rvm`, `rvm install 2.3.1`, `rvm use 2.3.1`
2. You'll need to set which new versions of gems/pods you want using `bundle exec gem update [gemname]` or `
bundle exec update [podname]` - specify a `gemname` or `podname` if there is a single gem/pod you wish to update, 
or leave off to update all to the latest allowed by their respective Gemfile/Podfile.
3. Run `bun/execute.sh setup` which installs gems, runs match, and installs pods (among other things)
4. If you have problems building/linking clean your project (shift-cmd-K) and clean the output folder (
shift-opt-cmd-K). The latter can correct linker issues regarding arm7 architecture and other weird problems where 
you can build for the simulator but not for a device.

Note: If you've upgraded CocoaPods to a version that changes its integration with XCode (ie. 0.39 to 1.0) then 
you might need to run `bundle exec pod deintegrate` then `bundle exec pod install` before opening and building 
your project.

---

## Expanding ios-tools

To add new capabilities refer to `script_usage()`, `parse_params()` and `run_task()` in `execute.sh` and the 
various components.
