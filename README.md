# Description

`zerg-larva` is a base shell script from which all other scripts and, ultimately, more complex components, can be created. Clone `zerg-larva` and mutate it into anything else.\
Build any shell script, by duplicating/cloning the original source file.

It supports:

* CLI POSIX compliant arguments management
* Embedded default arguments/operations: `--verbose`, `--help`, `--version`, `--list-exit-codes`
* Easy logging
* Verbose mode
* Default function template

# How to use this script

## Sections

The script is divided into sections, listed below.

### Safety Settings

Used to define more strict Bash behaviour.\
Modify only if required or for a specific purpose.

### User Globals

Modifiy the contents of this section to set up:
- Your Application Name
- Your Application Version

### Return Codes

Modifiy the contents of this section to set up all the return codes used by your script.\
`RC_OK=0` and `RC_UNKNOWN=125` should always been defined. Other codes are free to use, in the range **0–125**.

### Internal Globals

This section is used to init default system values. **Never** modify any variable here.

### Arguments 

This section lists all the arguments used by your script's command line. Their default values ​​are set to FALSE or empty, so they are enabled during pattern detection.

The following block then allows the value of these variables to be modified according to a string of characters detected in the command line.

The arguments `--help`, `--version`, `--verbose`, and `--list-exit-codes` are default arguments and should always be retained.

The `--directory` argument shows how to capture a string and use it as the target directory for further processing.

### Functions

This section defines the default functions made available by the script: `z_log()`, `z_die()`, `z_help()`, `z_list_exit_codes()`, `z_trace()`, `z_checkdep()`, and `z_dump()`.

The content of this section must not be modified.

### User Functions

This section defines user-created functions. All business functions must be placed here. The `get_timestamp()` function is a placeholder used as an example.

Note regarding user functions:

* A function should always return 0 on success;
* A function should always return a number greater than 0 on error. This number must be a constant listed in the `Return Codes` section.
* A fatal error encountered during execution should always trigger `exit()` or a `z_die()` call.

### Main

This section contains the main program, built from user-defined functions.

### Core

This section calls `main()`, displays help, version number or a list of return codes.

## Customization

1. Clone source file from `git` or unpack the provided archive

```console
asphyx@KERRIGAN:~/code$ git clone https://github.com/asphyx0r/zerg-larva.git ProjectName
asphyx@KERRIGAN:~/code$ cd ProjectName
```

2. Duplicate and rename original file `zerg-larva.sh` to your target script:

```console
asphyx@KERRIGAN:~/code$ mv ./zerg-larva.sh vxBackup.sh
```

3. Edit your new file with your favorite editor:

```console
asphyx@KERRIGAN:~/code$ nano vxBackup.sh 
```

4. **Line 3** to **Line 17** and beyond, document the script using the header template:

```bash
# Name        : <script_name>.sh
# Description : Short description of the script purpose.
# Usage       : script_name.sh [options]
# Author      : Your Name - Your Email
# Version     : v1.0.0
# Date        : 2025-12-01
# License     : MIT License
```

5. **Line 29**, edit the value of the variable `APPNAME` to set your application human-readable name:

```bash
readonly APPNAME="ApplicationName"
```

5. **Line 30**, edit the value of the variable `VERSION` to set your application version number:

```bash
readonly VERSION="v1.0.0"
```

6. **Line 46** to **Line 55**, list all the exit codes used by the script.

```bash
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
```

The free range is **0–125**:

Codes | Description
--- | ---
**0** | Success
**1-125** | Application errors (available for your script)
**126** | The command exists but cannot be executed
**127** | The command does not exist
**128+N** | The command terminated due to signal N. Example: 130 = 128+2, SIGINT = 2

Codes | Description
--- | ---
**126–127** | Reserved by POSIX for standard system error cases.
**128–255** | Reserved for signal terminations.



7. **Line 67** and later, assign a variable and a default value for each of your command line argument:

```bash
arg_help=false
arg_version=false
arg_verbose=false
arg_list_exit_codes=false
arg_directory=""
```

8. **Line 84** to **Line 100**, set the list of strings to be matched as arguments in the command line and assign it to the variables listed at step **7**:

```bash
        -h|--help)
            arg_help=true
            shift
            ;;
        --version)
            arg_version=true
            shift
            ;;
        -v|--verbose)
            arg_verbose=true
            shift
            ;;
        --list-exit-codes)
            arg_list_exit_codes=true
            shift
            ;;
        -d|--directory)
```

Some arguments can handle a second keyword. See `--directory` as example.
The string has to be defined but not be an argument by itself:

```bash
            if [[ -z "$arg_directory" || $arg_directory == "--"* || $arg_directory == "-"* ]] ; then
                echo "Missing DIRECTORY" >&2;
                echo "Try '$script_name --help' for more information.";
                RC=4
                exit $RC
            fi

            # DIRECTORY is followed by a directory string so shift 2
            shift 2
            ;;
```

## Default usage examples

- Print the script exit codes (no side effects):

```bash
zerg-larva.sh --list-exit-codes
```

- Run the script verbosely against a directory (must exist):

```bash
zerg-larva.sh --verbose -d /path/to/existing/directory
```

Notes:
- `--list-exit-codes` will print the RC mapping and exit 0.
- The script requires at least one argument; calling it with no args returns RC=1.

# Script Components

## Built-in Functions

### z_log(level, message)

------------------------------------------------------------------------------
 **NAME**
 
&emsp;&emsp;`z_log()` - Print a log line

 **SYNOPSIS**

&emsp; &emsp;`z_log <LEVEL> <MESSAGE>`

 **DESCRIPTION**
 
&emsp;&emsp;Displays the MESSAGE preceded by a timestamp and the LEVEL of the event.\
&emsp;&emsp;The local variable `function_name` is also displayed if available and defined.\
&emsp;&emsp;If not found, the default `undef()` function name is used.\
&emsp;&emsp;Level can be (FATAL|ERROR|WARN|INFO|DEBUG).\
&emsp;&emsp;The name of the calling function is automatically retrieved from log() via the Bash variable FUNCNAME[1].\
&emsp;&emsp;The line number where the log() function is called is recorded in the log message.

 **EXIT STATUS**
 
&emsp;&emsp;3  `RC_INTERNAL_LOG_ARGS`: Wrong number of arguments.

 **OUTPUT**
 
 &emsp;&emsp;`<LEVEL TIMESTAMP - FUNCTION: LOG LINE`
 
------------------------------------------------------------------------------

### z_help()

------------------------------------------------------------------------------
 **NAME**
 
&emsp;&emsp;`z_help()` - Display help and script usage information

 **SYNOPSIS**
 
&emsp; &emsp;`z_help`

 **DESCRIPTION**
 
&emsp;&emsp;Displays the script usage information on STDOUT.\
&emsp;&emsp;Modify the formatted block to fit you script arguments.\
&emsp;&emsp;This block should contain all the arguments listed in the ARGUMENTS section,\
&emsp;&emsp;declared at the beginning of the script via appropriate variables.

 **EXIT STATUS**
 
&emsp;&emsp;0

 **OUTPUT**
 
 &emsp;&emsp;Contents of `<<-EOF ... EOF` block
 
------------------------------------------------------------------------------

### z_list_exit_codes()

------------------------------------------------------------------------------
 **NAME**
 
&emsp;&emsp;`z_list_exit_codes()` - Display script exit codes information

 **SYNOPSIS**
 
&emsp; &emsp;`z_list_exit_codes`

 **DESCRIPTION**
 
&emsp;&emsp;List all script exit codes on STDOUT.\
&emsp;&emsp;Modify the formatted block to fit you script arguments.\
&emsp;&emsp;This block should contain all the codes listed in the\
&emsp;&emsp;RETURN CODES section, declared at the beginning of the script via constants.

 **EXIT STATUS**
 
&emsp;&emsp;0

 **OUTPUT**
 
 &emsp;&emsp;Contents of `<<-EOF ... EOF` block
 
------------------------------------------------------------------------------

### z_trace()

------------------------------------------------------------------------------
 **NAME**
 
&emsp;&emsp;`z_trace()` - Enable '`set -x`' tracing for debugging purpose

 **SYNOPSIS**
 
&emsp;&emsp;`z_trace BOOLEAN`\
&emsp;&emsp;0 : Disable tracing\
&emsp;&emsp;1 : Enable tracing

 **DESCRIPTION**
 
&emsp;&emsp;Enable '`set -x`' for local debugging.\
&emsp;&emsp;Your tracked code block should be enclosed between two `z_trace`calls:\
&emsp;&emsp;&emsp;&emsp;`z_trace 1`\
&emsp;&emsp;&emsp;&emsp;`<...>`\
&emsp;&emsp;&emsp;&emsp;`z_trace 0`

 **EXIT STATUS**
 
&emsp;&emsp;0 : Success\
&emsp;&emsp;RC_INTERNAL_TRC_ARGS if called with wrong number of arguments (1 expected)

 **OUTPUT**
 
 &emsp;&emsp;Bash debugging information
 
------------------------------------------------------------------------------

### z_die(exit_code, message)

------------------------------------------------------------------------------
 **NAME**
 
&emsp;&emsp;`z_die()` - Display error message then exit with return code

 **SYNOPSIS**
 
&emsp; &emsp;`z_die <EXIT_CODE> <MESSAGE>`

 **DESCRIPTION**

&emsp;&emsp;Displays the MESSAGE on STDOUT (error message)\
&emsp;&emsp;Exits with the provided EXIT_CODE

 **EXIT STATUS**
 
&emsp;&emsp;`<EXIT_CODE>`

 **OUTPUT**
 
 &emsp;&emsp;`ERROR <MESSAGE>`
 
------------------------------------------------------------------------------

### z_checkdep(command)

------------------------------------------------------------------------------
 **NAME**
 
&emsp;&emsp;`z_checkdep()` - Verify if required command is available.

 **SYNOPSIS**
 
&emsp; &emsp;`z_checkdep <COMMAND>`

 **DESCRIPTION**
 
&emsp;&emsp;Check if the given command exists in PATH.\
&emsp;&emsp;Return `true` if the dependency is found, `false` otherwise.

 **EXIT STATUS**
 
&emsp;&emsp;6 `RC_INTERNAL_DEP_ARGS`: Wrong number of arguments.\
&emsp;&emsp;Calling the function with a wrong number of arguments will `exit()`.\
&emsp;&emsp;(Being unable to check dependencies is a fatal error)\
&emsp;&emsp;Example:
```bash
	export sampleCommand="bash"
	if ! z_checkdep "$sampleCommand"; then
		z_die "$RC_MISSING_PREREQ" "A required dependency '$sampleCommand' is missing, cannot continue."
	fi
```

 **OUTPUT**
 
 &emsp;&emsp;Search result as DEBUG message (using `z_log` function)
 
------------------------------------------------------------------------------

### z_dump()

------------------------------------------------------------------------------
 **NAME**
 
&emsp;&emsp;`z_dump()` - Print debug information

 **SYNOPSIS**
 
&emsp; &emsp;`z_dump`

 **DESCRIPTION**
 
&emsp;&emsp;Print debug information about the script (name, path, full path, arguments, system variables).\
&emsp;&emsp;The `z_log()` function is used to output the system variables.

 **EXIT STATUS**
 
&emsp;&emsp;0

 **OUTPUT**
 
&emsp;&emsp;`script start date`\
&emsp;&emsp;`script start time`\
&emsp;&emsp;`script PID`\
&emsp;&emsp;`script PPID`\
&emsp;&emsp;`script full path`\
&emsp;&emsp;`script directory`\
&emsp;&emsp;`script name`\
&emsp;&emsp;`script path`\
&emsp;&emsp;`arguments`\
&emsp;&emsp;`user`\
&emsp;&emsp;`hostname`\
&emsp;&emsp;`bash version`
				 
------------------------------------------------------------------------------

### z_stacktrace()

------------------------------------------------------------------------------
 **NAME**
 
&emsp;&emsp;`z_stacktrace()` - Generate stack trace for debugging purpose

 **SYNOPSIS**
 
&emsp; &emsp;`z_stacktrace`

 **DESCRIPTION**
 
&emsp;&emsp;Display stack trace to STDOUT.\
&emsp;&emsp;Show parent function, script name and line number.

 **EXIT STATUS**
 
&emsp;&emsp;0

 **OUTPUT**
 
 &emsp;&emsp;Formatted  stack trace:
 ````
        Stack trace:
        ↳ f3 (zerg-larva.sh:448)
          ↳ f2 (zerg-larva.sh:449)
            ↳ f1 (zerg-larva.sh:450)
              ↳ main (zerg-larva.sh:451)
                ↳ main (zerg-larva.sh:484)
 ````                
				 
------------------------------------------------------------------------------

### z_trap_exit()

------------------------------------------------------------------------------
 **NAME**
 
&emsp;&emsp;`z_trap_exit()` - Basic EXIT trap

 **SYNOPSIS**
 
&emsp; &emsp;`trap 'z_trap_exit' EXIT`

 **DESCRIPTION**
 
&emsp;&emsp;This code snippet can be called when trapping an EXIT event.\
&emsp;&emsp;Show script return code, date and time of completion then duration.

 **EXIT STATUS**
 
&emsp;&emsp;Return the latest script RC

 **OUTPUT**
 
 &emsp;&emsp;Info log line:
 ````
[INFO]  2025-12-23 17:32:03 - z_trap_exit(462): Exiting (RC=0), End: 2025-12-23 17:32:03, Duration: 0s
 ````                
				 
------------------------------------------------------------------------------

### z_trap_error()

------------------------------------------------------------------------------
 **NAME**
 
&emsp;&emsp;`z_trap_error()` - Basic ERR trap

 **SYNOPSIS**
 
&emsp; &emsp;`trap 'z_trap_error' ERR`

 **DESCRIPTION**
 
&emsp;&emsp;This code snippet can be called when trapping an ERROR event.\
&emsp;&emsp;Show The latest error code, and the command/function which failed.

 **EXIT STATUS**
 
&emsp;&emsp;Return the latest command error code

 **OUTPUT**
 
 &emsp;&emsp;Info log line:
 ````
[ERROR] 2025-12-23 19:13:03 - z_trap_error(487): Command failed (rc=1) at ./zerg-larva.sh:625 in run_case(): "$@"
        Stack trace:
        ↳ z_trap_error (zerg-larva.sh:487)
          ↳ run_case (zerg-larva.sh:625)
            ↳ main (zerg-larva.sh:635)
              ↳ main (zerg-larva.sh:664)
 ````                
				 
------------------------------------------------------------------------------

### get_timestamp()

------------------------------------------------------------------------------
 **NAME**
 
&emsp;&emsp;`get_timestamp()` - Return a timestamp string

 **SYNOPSIS**
 
&emsp; &emsp;`get_timestamp`

 **DESCRIPTION**
 
&emsp;&emsp;Return a compact timestamp string.\
&emsp;&emsp;This function is a sample function to be used as template/skeleton\
&emsp;&emsp;The purpose is to populate the User Functions script section.

 **EXIT STATUS**
 
&emsp;&emsp;0

 **OUTPUT**
 
 &emsp;&emsp;Timestamp string (`YYYYmmdd-HHMMSS`)

 ------------------------------------------------------------------------------

### dummy_function()

------------------------------------------------------------------------------
 **NAME**
 
&emsp;&emsp;`dummy_function()` - Do nothing

 **SYNOPSIS**
 
&emsp; &emsp;`dummy_function`

 **DESCRIPTION**
 
&emsp;&emsp;Do nothing.\
&emsp;&emsp;This function is a sample function to be used as template/skeleton\
&emsp;&emsp;The purpose is to populate the User Functions script section.

 **EXIT STATUS**
 
&emsp;&emsp;0
&emsp;&emsp;124 `RC_DUMMY_ERROR`: Wrong number of arguments.

 **OUTPUT**
 
 &emsp;&emsp;Nothing

------------------------------------------------------------------------------        

### main()

 ------------------------------------------------------------------------------
 **NAME**
 
&emsp;&emsp;`main()` - Run the program

 **SYNOPSIS**
 
&emsp; &emsp;`main`

 **DESCRIPTION**
 
&emsp;&emsp;Primary driver.\
&emsp;&emsp;Logs start/end, optionally dumps debug info if verbose, demonstrates logging and exits with `$RC`.\
&emsp;&emsp;Your custom code must be called inside the `main()` function.\
&emsp;&emsp;Replace the content of the `main()`function with your Business Logic Functions.\
&emsp;&emsp;Change the value of `$RC` to handle errors and exit properly.

 **EXIT STATUS**
 
&emsp;&emsp;Return with the current value of `$RC` (default 0 unless changed earlier).

 **OUTPUT**
 
 &emsp;&emsp;None
 
------------------------------------------------------------------------------   

## Default exit codes (RC)

This script is provided with the following default exit codes.
This codes can be changed, or new one can be added. The free range is **0–125**:

- 0 — Success / default (no error)
- 1 — Missing operand (no arguments provided)
- 2 — Unknown operand (invalid option passed)
- 3 — Internal error: `z_log()` called with wrong number of arguments
- 4 — Missing DIRECTORY for `-d|--directory` option (directory argument not provided or invalid)
- 5 — Provided DIRECTORY does not exist or is not accessible
- 6 — Internal error: `z_checkdep()` called with wrong number of arguments
- 7 — Missing prerequisite (required command not found)
- 8 — Internal error: `z_trace()` called with wrong number of arguments
- 124 — Dummy error for demonstration purposes
- 125 — Unknown error

## Dependencies

This script requires the following external programs and shell features:

### External programs

- **bash(1)**
  - Used as the script interpreter (shebang `#!/usr/bin/env bash`). The script uses Bash-specific features such as `[[ ... ]]`, `local`, and `function`.
- **date(1)**
  - Used to generate timestamps in `z_log()` and `get_timestamp()` (format strings via `+FORMAT`).

### Shell features (provided by Bash)

- Conditional expressions `[[ ... ]]` and file tests `-d`, `-r`, `-x`.
- `case` / `shift` argument parsing.
- `local` variables inside functions.
- Here-documents (`cat <<-EOF`) for help and exit-code printing.
- Parameter expansions `${0##*/}`, `${@}`, `${0%/*}` and command substitution `$(...)`.

### Filesystem / permissions

- The script checks directories for existence and read/execute permissions; it assumes a POSIX-like filesystem and permission model.

### Portability notes

- Invoke with `bash zerg-larva.sh` or ensure the file is executable and the shebang is respected (`chmod +x zerg-larva.sh`).

# Usage

This script is provided by these default command line options.
Modify the content of the `z_help()` function to fit your needs:

```text
Usage: zerg-larva.sh [OPTION]

    -d, --directory DIRECTORY   set directory to work on
    -v, --verbose               print debugging information
    -h, --help                  display this help and exit
        --version               output version information and exit
        --list-exit-codes       print the list of script exit codes and exit
```

# Changelog

### v1.0.11 - ZRGLRV-0004 ZRGLRV-0003 (2025-12-22)
* e3073fd 2025-12-22 ZRGLRV-0003 Variables names switched to snake_case
* 6d5f094 2025-12-22 Added dummy_function() as template example
* 2ef1dde 2025-12-22 Added custom .editorconfig file to .gitignore
* ce9e8d9 2025-12-22 Updated .gitignore with more temp files

### v1.0.10 - Release v1.0.10 (2025-12-18)
* a49aa06 2025-12-18 Fixed wrong function names in documentation
* 01e843d 2025-12-18 Updated FILE_ID.DIZ with tag number v1.0.10
* edebbc1 2025-12-18 Added FILE_ID.DIZ for BBS distribution
* 6cad6f0 2025-12-18 Added ZERG.NFO file to project root
* 9c7e83c 2025-12-17 Internal functions renamed with "z_" prefix
* 6c67c2f 2025-12-17 getTimestamp() renamed to get_timestamp()
* 3a4f047 2025-12-17 Added .vscode to .gitignore
* 50f036b 2025-12-16 Updated .gitignore to include TODO.md
* 200b12b 2025-12-16 Fixed missing section separator in README.md/trace
* 3c3e2b9 2025-12-16 Shellcheck disabled for inused RC_UNKNOWN
* 488f3d9 2025-12-16 Renamed README.MD to README.md for consistency
* 41ccb95 2025-12-16 Global variable $RC set to EXIT CODE in die()
* 05d54fb 2025-12-08 CHANGELOG.md Update

### v1.0.9 - Improved debugging functions (2025-12-08)
* 82f56b7 2025-12-08 CHANGELOG.md Update
* f431d73 2025-12-08 Added stacktrace() function
* f6a26a8 2025-12-08 Fixed the reversal of return codes in checkdep()
* 785377c 2025-12-08 log(): Being unable to log is not a fatal error
* 934c012 2025-12-08 dump() function improvements
* fc448cb 2025-12-08 Updated README: new behavior of the log() function
* 2fa629d 2025-12-08 Log() function improvement
* 6313428 2025-12-08 Added line number tracking in trace() function
* f80fc25 2025-12-07 Documentation improvement

### v1.0.8 - Documentation improvement (2025-12-07)
* 0f35450 2025-12-07 Documentation improvement
* da96409 2025-12-07 Fixed typo in main() comment
* d4d0075 2025-12-07 Correction of the function return method
* b85cafe 2025-12-07 Added trace() function
* 72c14d0 2025-12-07 Added help() and list_exit_codes() functions
* c7ecbda 2025-12-06 Added die() and checkdep() functions

### v1.0.7 - Added die() and checkdep() functions (2025-12-06)
* 80ecf69 2025-12-06 Added die() and checkdep() functions
* ad08470 2025-12-06 Added man section for main() function

### v1.0.6 - 'man' section style documentation (2025-12-06)
* 930a638 2025-12-06 Added man section for main() function
* cd059ad 2025-12-06 Added man section for getTimestamp() function
* 2c72c41 2025-12-06 Added man section for dump() function
* e71dd2a 2025-12-06 Added man section for log() function
* 50b3b37 2025-12-06 Adding Bash docstrings to functions
* 293298e 2025-12-06 Fixed typo in RC list
* a966baf 2025-12-06 Improvements to the script structure and comments
* dd3c28d 2025-12-06 Update CHANGELOG/README for v1.0.5

### v1.0.5 - Update CHANGELOG/README for v1.0.5 (2025-12-06)
* f2a748b 2025-12-06 Update CHANGELOG/README for v1.0.5

### v1.0.4 - Automatic GHANGELOG generation (2025-12-06)
* 4281261 2025-12-06 Added tools used to generate CHANGELOG
* 4d6d9a9 2025-12-06 Update CHANGELOG for v1.0.4
* 99f8474 2025-12-06 Update CHANGELOG for v1.0.4
* 1e0c5fd 2025-11-30 Updated changelog with v1.0.3 commits

### v1.0.3 - Improved return code management (2025-11-30)
* 66cc2b2 2025-11-30 Return codes documentation
* 8d1bad3 2025-11-29 Improved return code management in zerg-larva.sh
* 3992a05 2025-11-29 Fixed wrong line break in README.MD
* f655366 2025-11-29 Updated .gitignore to exclude more files
* d707968 2025-11-27 Git customization

### v1.0.2 - Update README and script metadata for clarity and consistency, improved security fixes (2025-11-24)
* c5ffbf3 2025-11-22 Update README and script metadata for clarity and consistency, improved security fixes
* c8135a4 2025-11-21 Add safety settings to improve script robustness
* 5fadc91 2025-11-21 Enhance script header with detailed metadata and prerequisites

### v1.0.1 - Added Git default files (2025-11-08)
* 7c75b01 2025-11-08 Added Git default files

### v1.0.0 - Initial version/First commit (2025-11-08)
* 3bf9436 2025-11-08 Repo init: first commit

# Sources

* GitHub Home: [https://github.com/asphyx0r/zerg-larva](https://github.com/asphyx0r/zerg-larva)
* GitHub Repository: [https://github.com/asphyx0r/zerg-larva.git](https://github.com/asphyx0r/zerg-larva.git)
* Latests Release: [https://github.com/asphyx0r/zerg-larva/releases/latest/](https://github.com/asphyx0r/zerg-larva/releases/latest/)
