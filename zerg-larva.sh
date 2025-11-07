#!/usr/bin/env bash

# Global variables
readonly APPNAME="ApplicationName"
readonly VERSION="v1.0.0"

# System variables, I will use it later
RC=0
functionName="undef()"
scriptName=${0##*/}
scriptPath=${0%/*}
scriptFullPath=${0}
scriptArgs=${@}

# Arguments assignment, CLI/POSIX flavour
argHelp=false
argVersion=false
argVerbose=false
argListExitCodes=false
argDirectory=""

# I need at least one argument
if [ $# -eq 0 ]
  then
    echo "Missing operand"
    echo "Try '$scriptName --help' for more information."
    RC=1
    exit $RC
fi

# For each argument, search a pattern then shift to next argument
while [[ $# -gt 0 ]]; do
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
            argDirectory="$2";
            # DIRECTORY must be set when using -d operand, and followed by a string which is not an operand
            if [[ -z "$argDirectory" || $argDirectory == "--"* || $argDirectory == "-"* ]] ; then
                echo "Missing DIRECTORY" >&2;
                echo "Try '$scriptName --help' for more information.";
                RC=4
                exit $RC
            fi

            # DIRECTORY is followed by a directory string so shift 2
            shift 2
            ;;
        *)
          echo "Unknown operand: $1" >&2;
          echo "Try '$scriptName --help' for more information.";
          RC=2;
          exit $RC ;;
    esac
   
done

# The target directory must exist and be accessible
if [[ -n "$argDirectory" && ! -d "$argDirectory" && ! -r "$argDirectory" && ! -x "$argDirectory" ]]; then
    echo "Error: $argDirectory is not a valid or readable directory." >&2
    RC=5
    exit $RC
fi

# Easy logging, use: log "LEVEL" "Log message"
function log() {

    # Used for logging/debugging purpose
    # local functionName="log()"

    # Arguments assignation
    if [ $# -ne 2 ]; then
        echo -e "\tlog(): Error: 2 arguments required. Usage: log \"LEVEL\" \"Log message\""
        RC=3
        exit $RC
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

# Dump script informations for debug purpose
function dump() {

    # Used for logging/debugging purpose
    local functionName="dump()"

    log "DEBUG" "Script name: $scriptName"
    log "DEBUG" "Script path: $scriptPath"
    log "DEBUG" "Script full path: $scriptFullPath"
    log "DEBUG" "Script arguments: $scriptArgs"

}

# Some default function template/skeleton
function getTimestamp() {

    # Used for logging/debugging purpose
    local functionName="getTimestamp()"

    echo "$(date '+%Y%m%d-%H%M%S')"

}

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
  exit $RC
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