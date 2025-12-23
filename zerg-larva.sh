#!/usr/bin/env bash
#
# Name        : __SCRIPT_NAME__
# Description : __SCRIPT_DESCRIPTION__
# Usage       : __SCRIPT_NAME__ [options]
# Author      : __AUTHOR_NAME__ - __AUTHOR_EMAIL__
# Version     : __VERSION__
# Date        : __RELEASE_DATE__
# License     : __LICENSE_ID__
# Repository  : __REPOSITORY_URL__
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
readonly APPNAME="__APPNAME__"
readonly VERSION="__VERSION__"

# -[ RETURN CODES     ]---------------------------------------------------------
# Exit code constants (local to this script)
# The free range is 0–125
# RC_OK:                  0 — Success / default (no error)
# RC_MISSING_OPERAND:     1 — Missing operand (no arguments provided)
# RC_UNKNOWN_OPERAND:     2 — Unknown operand (invalid option passed)
# RC_INTERNAL_LOG_ARGS:   3 — Internal error: `zlog()` called with wrong number of arguments
# RC_MISSING_DIRECTORY:   4 — Missing DIRECTORY for `-d|--directory` option (directory argument not provided or invalid)
# RC_INVALID_DIRECTORY:   5 — Provided DIRECTORY does not exist or is not accessible
# RC_INTERNAL_DEP_ARGS:   6 — Internal error: `zcheckdep()` called with wrong number of arguments
# RC_MISSING_PREREQ:      7 — Missing prerequisite (required command not found)
# RC_INTERNAL_TRC_ARGS:   8 — Internal error: `z_trace()` called with wrong number of arguments
# RC_DUMMY_ERROR:        	124 — Dummy error for demonstration purposes
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
readonly RC_DUMMY_ERROR=124
# shellcheck disable=SC2034  # Unused variables left for readability
readonly RC_UNKNOWN=125

# -[ INTERNAL GLOBALS ]---------------------------------------------------------
# Default system variables, I will use it later. DO NOT MODIFY.
RC=$RC_OK
function_name="undef()"
readonly script_pid="$$"
readonly script_ppid="$PPID"
readonly script_name="${0##*/}"
readonly script_path="${0%/*}"
readonly script_args=("$@")
script_full_path="$(readlink -f "$0" 2>/dev/null || echo "$0")"
readonly script_full_path
script_dir=""
script_dir="$(dirname "$script_full_path")"
readonly script_dir
script_start_date=""
script_start_date="$(date +'%Y-%m-%d %H:%M:%S')"
readonly script_start_date
script_start_time=""
script_start_time="$(date +%s)"
readonly script_start_time

# -[ ARGUMENTS        ]---------------------------------------------------------
# Arguments assignment, CLI/POSIX flavour
arg_help=false
arg_version=false
arg_verbose=false
arg_list_exit_codes=false
arg_directory=""

# I need at least one argument
if [ "$#" -eq 0 ]; then
	printf '%s: missing operand\nTry: %s --help\n' "$0" "$0" >&2
	RC=$RC_MISSING_OPERAND
	exit "$RC"
fi

# For each argument, search a pattern then shift to next argument
while [[ "$#" -gt 0 ]]; do
	case "$1" in
	-h | --help)
		arg_help=true
		shift
		;;
	--version)
		arg_version=true
		shift
		;;
	-v | --verbose)
		arg_verbose=true
		shift
		;;
	--list-exit-codes)
		arg_list_exit_codes=true
		shift
		;;
	-d | --directory)
		# Check if the next argument is set (not empty, compliant with set -u)
		if [ -n "${2+x}" ]; then
			arg_directory="$2"
		fi
		# DIRECTORY must be set when using -d operand, and followed by a string which is not an operand
		if [[ -z "$arg_directory" || $arg_directory == "--"* || $arg_directory == "-"* ]]; then
			echo "Missing DIRECTORY" >&2
			echo "Try '$script_name --help' for more information."
			RC=$RC_MISSING_DIRECTORY
			exit "$RC"
		fi

		# DIRECTORY is followed by a directory string so shift 2
		shift 2
		;;
	*)
		echo "Unknown operand: $1" >&2
		echo "Try '$script_name --help' for more information."
		RC=$RC_UNKNOWN_OPERAND
		exit "$RC"
		;;
	esac

done

# The target directory must exist and be accessible
if [[ -n "$arg_directory" && ! -d "$arg_directory" && ! -r "$arg_directory" && ! -x "$arg_directory" ]]; then
	echo "Error: $arg_directory is not a valid or readable directory." >&2
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
	local function_name="${FUNCNAME[1]:-main}"

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
			printf '\tlog(): %s is not an allowed value, using DEBUG as default.\n' "$1"
			level="DEBUG"
			;;
		esac

		# Output the log message
		printf '[%s]\t%s - %s(%s): %s\n' \
			"$level" \
			"$(date +'%Y-%m-%d %H:%M:%S')" \
			"$function_name" \
			"$line" \
			"$message"

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
		Usage: $script_name [OPTION]
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
		RC=0   : Success / default (no error).
		RC=1   : Missing operand (no arguments provided).
		RC=2   : Unknown operand (invalid option passed).
		RC=3   : Internal error: log() called with wrong number of arguments.
		RC=4   : Missing DIRECTORY for -d|--directory option (directory argument not provided or invalid).
		RC=5   : Provided DIRECTORY does not exist (the target directory must exist and readable).
		RC=6   : Internal error: checkdep() called with wrong number of arguments
		RC=7   : Missing prerequisite (required command not found)
		RC=8   : Internal error: trace() called with wrong number of arguments
		RC=124 : Dummy error for demonstration purposes
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
		echo -e "\t$function_name: Error: 1 argument required. Usage: trace BOOLEAN"
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
		return "$RC_INTERNAL_DEP_ARGS"
	else

		local command_check="$1"

		z_log "DEBUG" "Checking prerequisites..."

		if command -v "$command_check" >/dev/null 2>&1; then
			z_log "DEBUG" "'$command_check' was found."
			return 0
		else
			z_log "ERROR" "'$command_check' was not found."
			return "$RC_MISSING_PREREQ"
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

	# Only dump information if verbose mode is enabled
	if [[ "$arg_verbose" != true ]]; then

		z_log "WARN" "Verbose mode is not enabled, cannot dump script information."
		return 0

	else

		z_log "DEBUG" "Dumping script information..."

		z_log "DEBUG" "Script start date: $script_start_date"
		z_log "DEBUG" "Script start time (epoch): $script_start_time"

		z_log "DEBUG" "Shell PID: $script_pid"
		z_log "DEBUG" "Shell PPID: $script_ppid"

		z_log "DEBUG" "Script full path: $script_full_path"
		z_log "DEBUG" "Script directory: $script_dir"
		z_log "DEBUG" "Script name: $script_name"
		z_log "DEBUG" "Script path: $script_path"

		# Properly display all array elements: https://www.shellcheck.net/wiki/SC2128
		z_log "DEBUG" "Script arguments: ${script_args[*]}"

		z_log "DEBUG" "User name: ${USER:-unknown}"
		z_log "DEBUG" "Host name: ${HOSTNAME:-unknown}"
		z_log "DEBUG" "Bash version: ${BASH_VERSION:-unknown}"

		return 0

	fi

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

	# Only dump information if verbose mode is enabled
	if [[ "$arg_verbose" != true ]]; then

		z_log "WARN" "Verbose mode is not enabled, cannot dump stacktrace."
		return 0

	else

		local depth="${#FUNCNAME[@]}"
		local i
		local n

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

	fi
}

# -[ TRAPS            ]---------------------------------------------------------

# name:     z_trap_exit()
# summary:  Basic trap: EXIT for cleanup
# usage:    trap 'z_trap_exit' EXIT
# example:  trap 'z_trap_exit' EXIT
# input:    None
# output:   Log to STDOUT
# return:	  Exit code of the script
# errors:		None
# shellcheck disable=SC2329
function z_trap_exit() {

	# Capture the EXIT code of the script
	local rc=$?

	# Backup shell options the disable errexit, nounset and xtrace
	local had_e=0 had_u=0 had_x=0
	[[ $- == *e* ]] && had_e=1
	[[ $- == *u* ]] && had_u=1
	[[ $- == *x* ]] && had_x=1
	set +e +u +x

	# Get end timestamp
	local end_ts
	end_ts="$(date +'%Y-%m-%d %H:%M:%S')"

	# Calculate script duration
	local duration_s="?"
	if [[ -n "${script_start_time:-}" ]]; then
		duration_s="$(($(date +%s) - script_start_time))"
	fi

	# Log the exit information
	if declare -F z_log >/dev/null 2>&1; then
		z_log "INFO" "Exiting (RC=${rc}), End: ${end_ts}, Duration: ${duration_s}s" || true
	else
		printf '[INFO]\t%s - main(0): Exiting (RC=%s), End: %s, Duration: %ss\n' \
			"$(date +'%Y-%m-%d %H:%M:%S')" "$rc" "$end_ts" "$duration_s"
	fi

	# Restore shell options saved before
	((had_x)) && set -x
	((had_u)) && set -u
	((had_e)) && set -e

	return "$rc"
}

# name:     z_trap_error()
# summary:  Basic trap: ERR handler to log context
# usage:
# example:
# input:
# output:
# return:
# errors:

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

# name:     dummy_function()
# summary:  Function placeholder / example
# usage:    dummy_function
# example:  dummy_function
# input:		Any arguments
# output:		None
# return:		0
# errors:		1 if no arguments passed
function dummy_function() {
	z_log "DEBUG" "Inside dummy_function"
	if
		(($# > 0))
	then
		z_log "DEBUG" "Arguments passed to dummy_function: $*"
		return 0
	else
		z_log "DEBUG" "No arguments passed to dummy_function"
		RC=$RC_DUMMY_ERROR
		return "$RC"
	fi

}

# -[ MAIN             ]---------------------------------------------------------
# Go-go-go Gadgetomain!
function main() {

	z_log "INFO" "$APPNAME $VERSION: Start"

	# Insert your main code below this line

	# Example: Sample line for the verbose flag
	z_dump

	# Example: Sample line for function output
	z_log "INFO" "$(get_timestamp)"

	# Example: Sample line for dummy function
	dummy_function "arg1" "arg2"
	# dummy_function

	# Example: Sample line for directory argument
	z_log "INFO" "Target directory is: $arg_directory"

	# Example: Sample lines for dependency check
	local sample_command="bash"
	if ! z_checkdep "$sample_command"; then
		z_die "$RC_MISSING_PREREQ" "A required dependency '$sample_command' is missing, cannot continue."
	fi

	# Example: Sample lines for debug mode
	#z_trace 1
	#export sampleVar="This is a sample variable"
	#z_log "DEBUG" "Sample variable value: $sampleVar"
	#z_trace 0

	# Example: Sample lines for stacktrace
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
if [[ "$arg_help" == true ]]; then
	z_help
	exit 0
elif [[ "$arg_version" == true ]]; then
	echo "$APPNAME $VERSION"
	exit 0
elif [[ "$arg_list_exit_codes" == true ]]; then
	z_list_exit_codes
	exit 0
else
	main || RC=$?
	exit "$RC"
fi
