#!/usr/bin/env bash

# # Requirements:
# - A shell script at `../.config.sh` that exports a PROJECT variable plus whatever is required by the comonents

# A better class of script
set -o errexit  # Exit on most errors (see the manual)
set -o errtrace # Make sure any error trap is inherited
set -o pipefail # Exit on failures earlier in a pipeline
# set -o xtrace  # Trace the execution of the script (debug)

# ASCII colour control codes for easier fancy output
default='\033[0m'
black='\033[30m'
red='\033[31m'
green='\033[32m'
yellow='\033[33m'
blue='\033[34m'
magenta='\033[35m'
cyan='\033[36m'
white='\033[36m'

# Learning stick
function script_usage() {
  echo -n "Usage:
  Available tasks:
    update                          Update the $PROJECT installation
      -ng|--no-git                    Skip updating Git repository
    test|unit-tests|ui-tests        Run all tests/unit tests/ui tests
      -c|--clean                      Clean before building
      -d|--destination                The destination (default: $DESTINATION)
    carthage                        Run carthage bootstrap
    carthage-update                 Run carthage update
    pods                            Run pod update
    ci-setup                        Setup Keychain and provisioning profiles
    clean                           Remove DerivedData directory
    itunes-connect                  Send a new build to iTunes Connect

  Common options:
    -nc|--no-colour                 Disable usage of coloured script status output
    --configuration                 Configuration to use"
}

# Nom the parameters
function parse_params() {
  while [[ $# -gt 0 ]]; do
    param="$1"
    shift
    case $param in
      -h|--help)
        script_usage
        exit 0
        ;;
      -nc|--no-colour)
        disable_colour
        ;;
      -c|--clean)
        clean=true
        ;;
      -d|--destination)
        destination="$1"
        shift
        ;;
      -ng|--no-git)
        check_tasksel 'update'
        no_git=true
        ;;
      *)
        check_tasksel
        task=$param
    esac
  done
  if [[ -z $destination ]]; then
    destination=$TEST_DESTINATION
  fi
}

function run_task() {
  if [[ $task = 'update' ]]; then
    update
  elif [[ $task = 'test' ]]; then
    unit_tests \
      && ui_tests
  elif [[ $task = 'unit-tests' ]]; then
    unit_tests
  elif [[ $task = 'ui-tests' ]]; then
    ui_tests
  elif [[ $task = 'pods' ]]; then
    pod_install
  elif [[ $task = 'carthage' ]]; then
    carthage_bootstrap
  elif [[ $task = 'carthage-update' ]]; then
    carthage_update
  elif [[ $task = 'ci-setup' ]]; then
    ci_setup
  elif [[ $task = 'clean' ]]; then
    clean
  elif [[ $task = 'itunes-connect' ]]; then
    itunes_connect
  else
    script_exit 1 "Invalid task: $param"
  fi
}

# Munge the parameters
function munge_params() {
  # If we were called by a symlink we set some parameters in advance based on
  # the name of the symlink. Essentially this implements some handy shortcuts!
  if [[ -h $script_dir/$script_name ]]; then
    # NB: Bypass raw_msg as we don't know yet if we want to disable colour msgs
    if [[ $script_name = 'git-update.sh' ]]; then
      task=update
    elif [[ $script_name = 'update.sh' ]]; then
      task=update
      no_git=true
    elif [[ $script_name = 'test.sh' ]]; then
      task=test
    fi
  fi
}

# Some generic initialisation we always perform
function script_init() {
  # So we can restore the original working directory
  orig_dir=$(pwd)
  # Name of the script
  script_name=$(basename "$0")
  # Path where the script resides
  script_dir=$(cd "$(dirname "$0")" && pwd)
  # We assume the app root is only one level up
  project_dir=$(cd "$(dirname "$script_dir")" && pwd)
}

# Exit script with the given code and message
function script_exit() {
  if [[ $# -eq 1 ]]; then
    echo -e "${red}$1${default}"
    exit 0
  fi

  if [[ $# -eq 2 && $1 =~ ^[0-9]+$ ]]; then
    echo -e "${red}$2${default}"
    exit $1
  fi

  script_exit 2 'Invalid arguments passed to script_exit()!'
}

# Handler for unexpected errors when encountered
function script_trap_err() {
  # Disable the error trap handler to prevent potential recursion
  trap - ERR

  # Consider any further errors non-fatal to ensure we run to completion
  set +o errexit
  set +o pipefail

  if [[ -n $comp_trap_err ]]; then
    $comp_trap_err
  fi
  # Print out some useful debugging output on the error condition
  if [[ -n $current_cmd ]]; then
    if [[ -n $cmd_output ]]; then
      echo "$cmd_output"
    fi
    echo -e "${red}Failed command: $current_cmd (within "$PWD")${default}"
  fi

  # Exit with failure status
  exit 1
}

function comp_init() {
  if [[ -n $comp_name && $comp_name != $1 ]]; then
    script_exit 2 "Call to comp_init $1 when comp_deinit has not been called"
  fi
  comp_name=$1
  comp_trap_err=$2
}

function comp_deinit() {
  if [[ -z $comp_name ]]; then
    script_exit 2 "Call to comp_deinit when comp_init has not been called"
  fi
  unset comp_name
  unset comp_trap_err
}

# Echo but make it pretty
function raw_msg() {
  if [[ $# -eq 1 ]]; then
    echo -e "${green}*** $1${default}"
  elif [[ $# -eq 2 ]]; then
    echo -e "${green}*** $1${default}: $2"
  elif [[ $# -eq 3 ]]; then
    echo -e "${green}*** $1${default} - ${magenta}$2${default}: $3"
  else
    script_exit 2 'Invalid arguments passed to raw_msg()!'
  fi
}

# Message shortcut for subscripts
function msg() {
  if [[ -z $comp_name ]]; then
    script_exit 2 'Called msg() without calling comp_init'
  fi
  if [[ $# -eq 1 ]]; then
    raw_msg "$comp_name" "$1"
  elif [[ $# -eq 2 ]]; then
    raw_msg "$comp_name" "$1" "$2"
  else
    script_exit 2 'Invalid arguments passed to msg()'
  fi
}

# Disable the usage of coloured output
function disable_colour() {
  no_colour=true
  default=''
  black=''
  red=''
  green=''
  yellow=''
  blue=''
  magenta=''
  cyan=''
  white=''
}

# Check only a single task was selected
function check_tasksel() {
  if [[ $# -eq 0 ]]; then
    if [[ -n $task ]]; then
      script_exit 1 'You must specify a single task.'
    fi
  else
    while [[ $# -gt 0 ]]; do
      if [[ $1 == $task ]]; then
        return
      fi
      shift
    done
    script_exit 1 'You tried to use a parameter not valid for the task.'
  fi
}

# Save a reference to an existing function (for overriding)
# All credit to: http://mivok.net/2009/09/20/bashfunctionoverrist.html
function save_function() {
  if [[ $# -ne 2 ]]; then
    script_exit 2 'Invalid arguments passed to save_function()!'
  fi

  local orig_func=$(declare -f $1)
  local new_func="$2${orig_func#$1}"
  eval "$new_func"
}

# Check a provided set of dependencies are present
function check_deps() {
  for dep in $@; do
    if ! command -v $dep > /dev/null; then
      script_exit 1 "Unable to find dependency in PATH: $dep"
    fi
  done
}

# Script initialisatsion
trap 'script_trap_err' ERR
script_init

cd "$project_dir"
source .config.sh
for file in $script_dir/components/*.sh; do
  source $file
done

munge_params
parse_params $@
# Output usage if no task is specified
if [[ $# -eq 0 && -z $task ]]; then
  script_usage
  exit 0
fi
run_task
cd "$orig_dir"
