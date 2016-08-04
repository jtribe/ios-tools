
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

(If you're using rvm to manage ruby versions and fish shell instead of bash, you can get rvm support under fish by following [these instructions](https://rvm.io/integration/fish).)

---

## Installation

### Adding The `ios-tools` Scripts
The following steps need to be performed once to setup the *ios-tools* scripts within your project.
Navigate to your projects directory in terminal and add perform the following commands.

```sh
git submodule add git@github.com:jtribe/ios-tools.git bin
touch .config.sh
bundle init
gemrat --pessimistic cocoapods xcpretty gym deliver match
```

This will result in a "bin" folder appearing, which will contain the shell files to be run in order to perform common tasks.

(n.b This will *NOT* setup codesigning for the project. Please refer to the "Codesigning" section of this ReadMe for its setup information.)

### Configuring Files

The file `.config.sh`, which should be in the project root directory, defines several variables that are used in the `ios-tools` scripts.
Open it up and set the variables to the appropriate values. It will look something like the following...

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

Note: `BUNDLE_IDENTIFIER` **Must Match** that used in xcode and on iTunes connect
(To use Circle-CI,these schemes must be shared. In Xcode, go to _Manage Schemes_ and tick the _Shared_ checkbox for each.)

---

## Codesigning

Codesigning is handled using the tool `match`, a product of `fastlane`. The tool `match` works by creating all of the necessary code signing files needed for development, then syncing them into one private git repository. By doing this, all developers on a team can use and access the same profiles and certificates. It also includes commands to make updating these files quick and easy.

#### 1. Create App ID
To begin, an `App ID` for the project must be created in the iOS Developer Member Centre. To do this
1. Login to the member centre using the teams apple account.
2. Navigate to the "Certificates, Identifiers & Profiles" section
3. Select `App IDs` in the left side menu, then select the "+" button, in the top right
(The App ID used here must match your project bundle ID, as well as any references you make to the App ID in configuration files)

#### 2. Login to Team in Xcode
Once an App ID is set up in the developer centre, navigate to XCode and make sure you are signed into your Team's Apple ID. You can check if you have already done this by navigating to xcode and selecting `Xcode -> Preferenes -> Accounts` and checking if your team appearing under the subheading "Apple IDs". if it doesn't, add it, by seelecting the "+" button and enerting the authentication details.

#### 3. Create Private Certificates Repository
You will now need to set up a private git repositry, which is where your codesigning documents will be securly kept. Navigate to the site where you wish to host this repositry (e.g. github, bitbucket) and create and empty repository. The recomended name is "{PROJECT_NAME}-Certificates".

#### 4. Create Everything Using `match`


- Run the following: `bundle exec match init` (Provide private certificates SSH URL when prompted)
- Open `Matchfile` and replace the url with your private certificates URL
- Create a file named `Appfile` and add the following...

```
app_identifier "com.example.appname"    # This is your BUNDLE_IDENTIFIER
apple_id "example@example.com.au"
team_id "12A345B6CD"                    # The Team ID as displayed in the Member Center - Login and click MEMBERSHIP in the sidebar.
itc_team_id "123456789"                 # itc_team_id can ONLY BE FOUND when CircleCI fails to login to iTunes Connect the first time. You'll see a list of teams available, and next to the name in brackets is a numerical value. Take the value you want, and use it for itc_team_id.
```
- Run `bundle exec match development` to create/store/retrieve development certificates and profiles.
- Run `bundle exec match appstore` to create/store/retrieve distribution certificates and profiles.

#### 5. More Information
If you have issues and require further reading, try [here](docs/code-signing-and-cd.md).

---

## Pods & Carthage

If using **Cocoa Pods**, the standard `bin/execute.sh setup` will handle the installation of pods specified in the Podfile.

If using **Carthage**, the standard `bin/execute.sh setup` will handle the download and building of frameworks specified in the Cartfile. They will still need to be added to the Xcode project manually, if not yet done so.

(If using Circle-CI, ensure you checkin the built frameworks to the repository, as it does not build them when running.)

---

## Circle-CI Configuration

### Add `circle.yml` File

Add a `circle.yml` file to the root directory of the project. A typical `circle.yml` setup is as
follows. (n.b. The SSH Key will never change.)


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

### Enable Builds On Circle CI

After you've done the above step, an admin of the repository will need to go into Circle-CI and allow builds for the project.

In order for CircleCI to be able to fetch this repository (ios-tools) as a submodule, you will need to [add a "user
key" to the Project Settings](https://circleci.com/docs/external-resources).


## Usage
Most functions are accessed using a simple scripting framework in `bin/execute.sh` that provides access
to the functions in `bin/components`.

- Run `bin/execute.sh` for usage
- Run `bin/execute.sh setup` to setup your dev environment
- Run `bin/update.sh` to update the project dependencies
- Run `bin/git-update.sh` to pull changes from upstream and update the project dependencies

Once all area are setup, developers *should* simply have to run `bin/execute.sh setup` to have ios-tools setup and create everything.

---

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

---

## Expanding ios-tools

To add new capabilities refer to `script_usage()`, `parse_params()` and `run_task()` in `execute.sh` and the various components.
