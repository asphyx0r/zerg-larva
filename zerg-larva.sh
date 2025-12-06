#!/usr/bin/env bash
#
# Name        : <script_name>.sh
# Description : Short description of the script purpose.
# Usage       : script_name.sh [options]
# Author      : Your Name - Your Email
# Version     : v1.0.0
# Date        : 2025-12-01
# License     : MIT License
#
# Prerequisites:
#   - Linux system running Debian 11 or later
#   - Bash shell (this script requires bash-specific features)
#   - Required commands: grep, sed, awk, curl/wget (adjust as needed)
#   - Sufficient permissions for file or directory operations
#   - Network connectivity if remote calls are performed
#
# Notes:
#   - This script is not POSIX-compliant; do not run it under /bin/sh.
#

# -[ SAFETY SETTINGS  ]---------------------------------------------------------
set -o errexit
set -o nounset
set -o pipefail
IFS=$' \t\n'

# -[ USER GLOBALS     ]---------------------------------------------------------
readonly APPNAME="ApplicationName"
readonly VERSION="v1.0.0"

# -[ RETURN CODES     ]---------------------------------------------------------
# Exit code constants (local to this script)
# RC_OK:                  0 — Success / default (no error)
# RC_MISSING_OPERAND:     1 — Missing operand (no arguments provided)
# RC_UNKNOWN_OPERAND:     2 — Unknown operand (invalid option passed)
# RC_INTERNAL_LOG_ARGS:   3 — Internal error: `log()` called with wrong number of arguments
# RC_MISSING_DIRECTORY:   4 — Missing DIRECTORY for `-d|--directory` option (directory argument not provided or invalid)
# RC_INVALID_DIRECTORY:   5 — Provided DIRECTORY does not exist or is not accessible
# RC_UNKNOWN:             125 — Unknown error
readonly RC_OK=0
readonly RC_MISSING_OPERAND=1
readonly RC_UNKNOWN_OPERAND=2
readonly RC_INTERNAL_LOG_ARGS=3
readonly RC_MISSING_DIRECTORY=4
readonly RC_INVALID_DIRECTORY=5
readonly RC_UNKNOWN=125

# -[ INTERNAL GLOBALS ]---------------------------------------------------------
# System variables, I will use it later
RC=$RC_OK
functionName="undef()"
readonly scriptName="${0##*/}"
readonly scriptPath="${0%/*}"
readonly scriptFullPath="${0}"
scriptArgs=${@}

# -[ ARGUMENTS        ]---------------------------------------------------------
# Arguments assignment, CLI/POSIX flavour
argHelp=false
argVersion=false
argVerbose=false
argListExitCodes=false
argDirectory=""

# I need at least one argument
if [ "$#" -eq 0 ]
    then
        echo "Missing operand"
        echo "Try '$scriptName --help' for more information."
            RC=$RC_MISSING_OPERAND
            exit "$RC"
fi

# For each argument, search a pattern then shift to next argument
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -h|--help)
            argHelp=true
            shift
            ;;
        --version)
            argVersion=true
            shift
            ;;
        -v|--verbose)
            argVerbose=true
            shift
            ;;
        --list-exit-codes)
            argListExitCodes=true
            shift
            ;;
        -d|--directory)
            # Check if the next argument is set (not empty, compliant with set -u)
            if [ -n "${2+x}" ]; then
                argDirectory="$2";
            fi
            # DIRECTORY must be set when using -d operand, and followed by a string which is not an operand
            if [[ -z "$argDirectory" || $argDirectory == "--"* || $argDirectory == "-"* ]] ; then
                echo "Missing DIRECTORY" >&2;
                echo "Try '$scriptName --help' for more information.";
                RC=$RC_MISSING_DIRECTORY
                exit "$RC"
            fi

            # DIRECTORY is followed by a directory string so shift 2
            shift 2
            ;;
                *)
                    echo "Unknown operand: $1" >&2;
                    echo "Try '$scriptName --help' for more information.";
                    RC=$RC_UNKNOWN_OPERAND;
                    exit "$RC" ;;
    esac
   
done

# The target directory must exist and be accessible
if [[ -n "$argDirectory" && ! -d "$argDirectory" && ! -r "$argDirectory" && ! -x "$argDirectory" ]]; then
    echo "Error: $argDirectory is not a valid or readable directory." >&2
    RC=$RC_INVALID_DIRECTORY
    exit "$RC"
fi

# -[ FUNCTIONS        ]---------------------------------------------------------

# name:     log()
# summary:  Easy logging
# usage:    log <LEVEL> <MESSAGE>
# example:  log "INFO" "This is an informational message."
# input:    $1: LEVEL (FATAL, ERROR, WARN, INFO, DEBUG)
#           $2: Log message
# output:   String to STDOUT
# return:   None, output log message to STDOUT
# errors:   $RC_INTERNAL_LOG_ARGS if not called with 2 arguments
function log() {

    # Used for logging/debugging purpose
    # local functionName="log()"

    # Arguments assignation
    if [ "$#" -ne 2 ]; then
        echo -e "\tlog(): Error: 2 arguments required. Usage: log \"LEVEL\" \"Log message\""
        RC=$RC_INTERNAL_LOG_ARGS
        exit "$RC"
    else
    
        local level="$1"
        local message="$2"

        # Check if the LEVEL is set to an allowed value
        case "$1" in
            FATAL|ERROR|WARN|INFO|DEBUG)
                ;; # Allowed values baby
            *)
                # Set to DEBUG if not allowed
                echo -e "\tlog(): $1 is not an allowed value, using DEBUG as default."
                level="DEBUG"
                ;;
        esac

        echo -e "[$level]\t$(date +'%Y-%m-%d %H:%M:%S') - $functionName: $message"

    fi

}

# name:     dump()
# summary:  Dump script informations for debug purpose
# usage:    dump
# example:  dump
# input:    None
# output:   String to STDOUT
# return:   None, output log messages to STDOUT
# errors:   None
function dump() {

    # Used for logging/debugging purpose
    local functionName="dump()"

    log "DEBUG" "Script name: $scriptName"
    log "DEBUG" "Script path: $scriptPath"
    log "DEBUG" "Script full path: $scriptFullPath"
    log "DEBUG" "Script arguments: $scriptArgs"

}

# -[ USER FUNCTIONS   ]---------------------------------------------------------

# name:     getTimestamp()
# summary:  Some default function template/skeleton
# usage:    getTimestamp
# example:  getTimestamp
# input:    None
# output:   String to STDOUT
# return:   None, output string to STDOUT
# errors:   None
function getTimestamp() {

    # Used for logging/debugging purpose
    local functionName="getTimestamp()"

    echo "$(date '+%Y%m%d-%H%M%S')"

}

# -[ MAIN             ]---------------------------------------------------------
# Go-go-go Gadgetomain!
function main() {

  # Used for logging/debugging purpose
  local functionName="main()"

  log "INFO" "$APPNAME $VERSION: Start"

  # Sample line for the verbose flag
  if [[ "$argVerbose" == true ]]; then 
      dump
  fi

  # Sample line for function output
  log "INFO" "$(getTimestamp)"

  # Some log level examples
  log "FATAL" "This is a fatal error, exiting..."
  log "ERROR" "Unable to connect the database"
  log "WARN" "Configuration file missing, using default values"
  log "INFO" "Successfully connected to the database"
  log "DEBUG" "Information for debugging purpose only"
  log "WRONG" "This value is not allowed, I don't trust you"

    log "INFO" "$APPNAME $VERSION: End ($RC)"
    exit "$RC"
}

# Here is the core: Display help, version or run main()
if [[ "$argHelp" == true ]]; then
    cat <<-EOF
Usage: $scriptName [OPTION]
Do anything with the DIRECTORY, if it really exists.

Mandatory arguments to long options are mandatory for short options too.
  -d, --directory DIRECTORY   set directory to work on
  -v, --verbose               print debbuging information
  -h, --help                  display this help and exit
      --version               output version information and exit
      --list-exit-codes       list of exit codes
EOF
    exit 0
elif [[ "$argVersion" == true ]]; then
    echo "$APPNAME $VERSION"
    exit 0
elif [[ "$argListExitCodes" == true ]]; then
    cat <<-EOF
RC=0 : Success / default (no error).
RC=1 : Missing operand (no arguments provided).
RC=2 : Unknown operand (invalid option passed).
RC=3 : Internal error: log() called with wrong number of arguments.
RC=4 : Missing DIRECTORY for -d|--directory option (directory argument not provided or invalid).
RC=5 : Provided DIRECTORY does not exist (the target directory must exist and readable).
EOF
    exit 0
else
    main
fi