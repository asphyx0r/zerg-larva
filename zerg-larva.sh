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
# The free range is 0–125
# RC_OK:                  0 — Success / default (no error)
# RC_MISSING_OPERAND:     1 — Missing operand (no arguments provided)
# RC_UNKNOWN_OPERAND:     2 — Unknown operand (invalid option passed)
# RC_INTERNAL_LOG_ARGS:   3 — Internal error: `log()` called with wrong number of arguments
# RC_MISSING_DIRECTORY:   4 — Missing DIRECTORY for `-d|--directory` option (directory argument not provided or invalid)
# RC_INVALID_DIRECTORY:   5 — Provided DIRECTORY does not exist or is not accessible
# RC_INTERNAL_DEP_ARGS:   6 — Internal error: `checkdep()` called with wrong number of arguments
# RC_MISSING_PREREQ:      7 — Missing prerequisite (required command not found)
# RC_INTERNAL_TRC_ARGS:   8 — Internal error: `trace()` called with wrong number of arguments
# RC_UNKNOWN:             125 — Unknown error
readonly RC_OK=0
readonly RC_MISSING_OPERAND=1
readonly RC_UNKNOWN_OPERAND=2
readonly RC_INTERNAL_LOG_ARGS=3
readonly RC_MISSING_DIRECTORY=4
readonly RC_INVALID_DIRECTORY=5
readonly RC_INTERNAL_DEP_ARGS=6
readonly RC_MISSING_PREREQ=7
readonly RC_INTERNAL_TRC_ARGS=8
# shellcheck disable=SC2034  # Unused variables left for readability
readonly RC_UNKNOWN=125

# -[ INTERNAL GLOBALS ]---------------------------------------------------------
# Default system variables, I will use it later. DO NOT MODIFY.
RC=$RC_OK
functionName="undef()"
readonly scriptPID="$$"
readonly scriptPPID="$PPID"
readonly scriptName="${0##*/}"
readonly scriptPath="${0%/*}"
readonly scriptArgs=("$@")
scriptFullPath="$(readlink -f "$0" 2>/dev/null || echo "$0")"
readonly scriptFullPath
scriptDir=""
scriptDir="$(dirname "$scriptFullPath")"
readonly scriptDir
scriptStartDate=""
scriptStartDate="$(date +'%Y-%m-%d %H:%M:%S')"
readonly scriptStartDate
scriptStartTime=""
scriptStartTime="$(date +%s)"
readonly scriptStartTime

# -[ ARGUMENTS        ]---------------------------------------------------------
# Arguments assignment, CLI/POSIX flavour
argHelp=false
argVersion=false
argVerbose=false
argListExitCodes=false
argDirectory=""

# I need at least one argument
if [ "$#" -eq 0 ]; then
	echo "Missing operand"
	echo "Try '$scriptName --help' for more information."
	RC=$RC_MISSING_OPERAND
	exit "$RC"
fi

# For each argument, search a pattern then shift to next argument
while [[ "$#" -gt 0 ]]; do
	case "$1" in
	-h | --help)
		argHelp=true
		shift
		;;
	--version)
		argVersion=true
		shift
		;;
	-v | --verbose)
		argVerbose=true
		shift
		;;
	--list-exit-codes)
		argListExitCodes=true
		shift
		;;
	-d | --directory)
		# Check if the next argument is set (not empty, compliant with set -u)
		if [ -n "${2+x}" ]; then
			argDirectory="$2"
		fi
		# DIRECTORY must be set when using -d operand, and followed by a string which is not an operand
		if [[ -z "$argDirectory" || $argDirectory == "--"* || $argDirectory == "-"* ]]; then
			echo "Missing DIRECTORY" >&2
			echo "Try '$scriptName --help' for more information."
			RC=$RC_MISSING_DIRECTORY
			exit "$RC"
		fi

		# DIRECTORY is followed by a directory string so shift 2
		shift 2
		;;
	*)
		echo "Unknown operand: $1" >&2
		echo "Try '$scriptName --help' for more information."
		RC=$RC_UNKNOWN_OPERAND
		exit "$RC"
		;;
	esac

done

# The target directory must exist and be accessible
if [[ -n "$argDirectory" && ! -d "$argDirectory" && ! -r "$argDirectory" && ! -x "$argDirectory" ]]; then
	echo "Error: $argDirectory is not a valid or readable directory." >&2
	RC=$RC_INVALID_DIRECTORY
	exit "$RC"
fi

# -[ FUNCTIONS        ]---------------------------------------------------------

# name:     z_log()
# summary:  Easy logging
# usage:    z_log <LEVEL> <MESSAGE>
# example:  z_log "INFO" "This is an informational message."
# input:    $1: LEVEL (FATAL, ERROR, WARN, INFO, DEBUG)
#           $2: Log message
# output:   String to STDOUT
# return:   0 in case of success
# errors:   $RC_INTERNAL_LOG_ARGS if not called with 2 arguments
function z_log() {

	# Get the caller function name, or 'main' if called from main script
	local functionName="${FUNCNAME[1]:-main}"

	# Arguments assignation
	if [ "$#" -ne 2 ]; then
		echo -e "\tlog(): Error: 2 arguments required. Usage: log \"LEVEL\" \"Log message\""
		RC=$RC_INTERNAL_LOG_ARGS
		# Being unable to log is not a fatal error but should be tested by the caller
		# exit "$RC"
		return "$RC"
	else

		local level="$1"
		local message="$2"
		# Get the line number where log() was called
		local line="${BASH_LINENO[0]}"

		# Check if the LEVEL is set to an allowed value
		case "$1" in
		FATAL | ERROR | WARN | INFO | DEBUG) ;; # Allowed values baby
		*)
			# Set to DEBUG if not allowed
			echo -e "\tlog(): $1 is not an allowed value, using DEBUG as default."
			level="DEBUG"
			;;
		esac

		echo -e "[$level]\t$(date +'%Y-%m-%d %H:%M:%S') - $functionName($line): $message"

		return 0

	fi

}

# name:     z_die()
# summary:  Display error message then exit with return code
# usage:    z_die <EXIT_CODE> <MESSAGE>
# example:  z_die 1 "This is a fatal error."
# input:    $1: EXIT_CODE (integer)
#           $2: Error message (string)
# output:   String to STDOUT (error message)
# return:   None
# errors:   Exits with the provided EXIT_CODE
function z_die() {

	local exit_code="$1"
	shift
	z_log "ERROR" "$@"
	RC=$exit_code
	exit "$exit_code"

}

# name:     z_help()
# summary:  Display help and script usage information
# usage:    z_help
# example:  z_help
# input:    None
# output:   String to STDOUT (script usage)
# return:   0
# errors:   None
function z_help() {

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

	return 0
}

# name:     z_list_exit_codes()
# summary:  Display script exit codes information
# usage:    z_list_exit_codes
# example:  z_list_exit_codes
# input:    None
# output:   String to STDOUT (RC list)
# return:   0
# errors:   None
function z_list_exit_codes() {

	cat <<-EOF
		RC=0 : Success / default (no error).
		RC=1 : Missing operand (no arguments provided).
		RC=2 : Unknown operand (invalid option passed).
		RC=3 : Internal error: log() called with wrong number of arguments.
		RC=4 : Missing DIRECTORY for -d|--directory option (directory argument not provided or invalid).
		RC=5 : Provided DIRECTORY does not exist (the target directory must exist and readable).
		RC=6 : Internal error: checkdep() called with wrong number of arguments
		RC=7 : Missing prerequisite (required command not found)
		RC=8 : Internal error: trace() called with wrong number of arguments
		RC=125 : Unknown error
	EOF

	return 0
}

# name:     z_trace()
# summary:  Enable 'set -x' tracing for debugging purpose
# usage:    z_trace BOOLEAN
# example:  z_trace 1
# input:    $1: 1 or 0 (enable/disable tracing)
# output:   Debugging information to STDERR
# return:   0 on success
# errors:   RC_INTERNAL_TRC_ARGS if called with wrong number of arguments (1 expected)
# shellcheck disable=SC2329
function z_trace() {

	# Arguments assignation
	if [ "$#" -ne 1 ]; then
		echo -e "\t$functionName: Error: 1 argument required. Usage: trace BOOLEAN"
		RC=$RC_INTERNAL_TRC_ARGS
		return "$RC_INTERNAL_TRC_ARGS"
	fi

	local line="${BASH_LINENO[0]}"
	echo "Line number: $line"

	if [[ "$1" -eq 1 ]]; then
		set -x
	else
		set +x 2>/dev/null || true
	fi

	return 0

}

# name:     z_checkdep()
# summary:  Check dependencies. Verify if required command is available.
# usage:    z_checkdep <DEPENDENCY>
# example:  z_checkdep "curl"
# input:    $1: DEPENDENCY (string, command to check)
# output:   Check result to STDOUT (via log function)
# return:   True if the dependency is found, False otherwise
# errors:   Exit with RC_INTERNAL_DEP_ARGS if called with wrong number of arguments (1 expected)
function z_checkdep() {

	# Arguments assignation
	# Argument cannot be empty nor missing
	if [[ -z ${1:-} ]]; then
		z_log "ERROR" "Missing argument DEPENDENCY. Usage: z_checkdep \"DEPENDENCY\""
		RC=$RC_INTERNAL_DEP_ARGS
		# Being unable to check dependencies is a fatal error
		exit "$RC"
		#return "$RC"
	else

		local commandCheck="$1"

		z_log "DEBUG" "Checking prerequisites..."

		if command -v "$commandCheck" >/dev/null 2>&1; then
			z_log "DEBUG" "'$commandCheck' was found."
			return 0
		else
			z_log "ERROR" "'$commandCheck' was not found."
			return 1
		fi

	fi

}

# name:     z_dump()
# summary:  Dump script informations for debug purpose
# usage:    z_dump
# example:  z_dump
# input:    None
# output:   String to STDOUT
# return:   0
# errors:   None
function z_dump() {

	z_log "DEBUG" "Script start date: $scriptStartDate"
	z_log "DEBUG" "Script start time (epoch): $scriptStartTime"

	z_log "DEBUG" "Shell PID: $scriptPID"
	z_log "DEBUG" "Shell PPID: $scriptPPID"

	z_log "DEBUG" "Script full path: $scriptFullPath"
	z_log "DEBUG" "Script directory: $scriptDir"
	z_log "DEBUG" "Script name: $scriptName"
	z_log "DEBUG" "Script path: $scriptPath"

	# Properly display all array elements: https://www.shellcheck.net/wiki/SC2128
	z_log "DEBUG" "Script arguments: ${scriptArgs[*]}"

	z_log "DEBUG" "User name: $USER"
	z_log "DEBUG" "Host name: $HOSTNAME"
	z_log "DEBUG" "Bash version: $BASH_VERSION"

	return 0

}

# name:     z_stacktrace()
# summary:  Generate stack trace for debugging purpose
# usage:    z_stacktrace
# example:  z_stacktrace
# input:    None
# output:   Display stack trace to STDOUT
# return:   0
# errors:   None
function z_stacktrace() {

	local depth="${#FUNCNAME[@]}"
	local i

	printf "\tStack trace:\n"

	# stacktrace starts at 1 to skip the current function (stacktrace)
	for ((i = 1; i < depth; i++)); do

		local func="${FUNCNAME[$i]}"
		local file="${BASH_SOURCE[$i]##*/}"
		local line="${BASH_LINENO[$((i - 1))]}"

		# Identation based on stack depth
		local indent=""
		for ((n = 1; n < i; n++)); do
			indent+="  "
		done

		printf '\t%s↳ %s (%s:%s)\n' "$indent" "$func" "$file" "$line"

	done

	return 0
}

# -[ USER FUNCTIONS   ]---------------------------------------------------------

# name:     get_timestamp()
# summary:  Some default function template/skeleton
# usage:    get_timestamp
# example:  get_timestamp
# input:    None
# output:   String to STDOUT
# return:   0
# errors:   None
function get_timestamp() {

	# echo "$(date '+%Y%m%d-%H%M%S')"
	date '+%Y%m%d-%H%M%S'

	return 0

}

# -[ MAIN             ]---------------------------------------------------------
# Go-go-go Gadgetomain!
function main() {

	z_log "INFO" "$APPNAME $VERSION: Start"

	# Insert your main code below this line

	# Example: Sample line for the verbose flag
	if [[ "$argVerbose" == true ]]; then
		z_dump
	fi

	# Example: Sample line for function output
	z_log "INFO" "$(get_timestamp)"

	# Example: Sample line for directory argument
	z_log "INFO" "Target directory is: $argDirectory"

	# Example: Sample lines for dependency check
	export sampleCommand="bash"
	if ! z_checkdep "$sampleCommand"; then
		z_die "$RC_MISSING_PREREQ" "A required dependency '$sampleCommand' is missing, cannot continue."
	fi

	# Example: Sample lines for debug mode
	#z_trace 1
	#export sampleVar="This is a sample variable"
	#z_log "DEBUG" "Sample variable value: $sampleVar"
	#z_trace 0

	# Example: Sample lines for stacktrace
	z_log "DEBUG" "Generating stacktrace..."
	f3() { z_stacktrace; }
	f2() { f3; }
	f1() { f2; }
	f1

	# Example: Some log level examples
	z_log "FATAL" "This is a fatal error, exiting..."
	z_log "ERROR" "Unable to connect the database"
	z_log "WARN" "Configuration file missing, using default values"
	z_log "INFO" "Successfully connected to the database"
	z_log "DEBUG" "Information for debugging purpose only"
	z_log "WRONG" "This value is not allowed, I don't trust you"

	# Example: set RC to non-zero if a simulated error occurs
	# Uncomment the next line to simulate an error exit
	# RC=$RC_UNKNOWN

	# Insert your main code above this line

	z_log "INFO" "$APPNAME $VERSION: End ($RC)"
	return "$RC"
}

# -[ CORE             ]---------------------------------------------------------
# Here is the core: Display help, version or run main()
# Do not modify this part unless you know what you are doing
if [[ "$argHelp" == true ]]; then
	z_help
	exit 0
elif [[ "$argVersion" == true ]]; then
	echo "$APPNAME $VERSION"
	exit 0
elif [[ "$argListExitCodes" == true ]]; then
	z_list_exit_codes
	exit 0
else
	main
	exit "$RC"
fi
