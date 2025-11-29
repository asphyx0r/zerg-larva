# General informations

## Author

me@asphyx.fr

## Changelog

### v1.0.0 - Initial version (13/10/2025)
* 3bf9436 2025-11-08 Repo init: first commit

### v1.0.1 - Added Git default files (08/11/2025)
* 7c75b01 2025-11-08 Added Git default files

### v1.0.2 - Improved security fixes (24/11/2025)
* c5ffbf3 2025-11-22 Update README and script metadata for clarity and consistency, improved security fixes
* c8135a4 2025-11-21 Add safety settings to improve script robustness
* 5fadc91 2025-11-21 Enhance script header with detailed metadata and prerequisites

## Description

`zerg-larva` is a base shell script from which all other scripts and, ultimately, more complex components, can be created. Clone `zerg-larva` and mutate it into anything else.

Build any shell script, by duplicating/cloning the original source file.

It supports:

* CLI POSIX compliant arguments management
* Embedded default arguments/operations: `--verbose`, `--help`, `--version`, `--list-exit-codes`
* Easy logging
* Verbose mode
* Default function template

## Sources

* GitHub Home: [https://github.com/asphyx0r/zerg-larva](https://github.com/asphyx0r/zerg-larva)
* GitHub Repository: [https://github.com/asphyx0r/zerg-larva.git](https://github.com/asphyx0r/zerg-larva.git)
* Latests Release: [https://github.com/asphyx0r/zerg-larva/releases/latest/](https://github.com/asphyx0r/zerg-larva/releases/latest/)

# How to use this script

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

4. **Line 27**, edit the value of the variable `APPNAME` to set your application human-readable name:

```bash
readonly APPNAME="ApplicationName"
```

5. **Line 28**, edit the value of the variable `VERSION` to set your application version number:

```bash
readonly VERSION="v1.0.0"
```

6. **Line 39** and later, assign a variable and a default value for each of your command line argument:

```bash
argHelp=false
argVersion=false
argVerbose=false
argListExitCodes=false
argDirectory=""
```

7. **Line 57** to **Line 73**, set the list of strings to be matched as arguments in the command line and assign it to the variables listed at step **6**:

```bash
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
```

Some arguments can handle a second keyword. See `--directory` as example.
The string has to be defined but not be an argument by itself:

```bash
            if [[ -z "$argDirectory" || $argDirectory == "--"* || $argDirectory == "-"* ]] ; then
                echo "Missing DIRECTORY" >&2;
                echo "Try '$scriptName --help' for more information.";
                RC=4
                exit $RC
            fi

            # DIRECTORY is followed by a directory string so shift 2
            shift 2
            ;;
```

8. **Line 3** to **Line 17** and beyond, document the script using the header template.

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

## Functions

- **log(level, message)**
	- Arguments: level (FATAL|ERROR|WARN|INFO|DEBUG), message (string)
	- Goal: Print a timestamped log line with the given level.
	- Return codes: exits with RC=3 if called with wrong number of arguments.

- **dump()**
	- Arguments: none
	- Goal: Print debug information about the script (name, path, full path, arguments) using `log`.
	- Return codes: none directly (may exit via `log` if `log` fails).

- **getTimestamp()**
	- Arguments: none
	- Goal: Return a compact timestamp string (YYYYmmdd-HHMMSS).
	- Return codes: none

- **main()**
	- Arguments: none (uses global args)
	- Goal: Primary driver: logs start/end, optionally dumps debug info if verbose, demonstrates logging and exits with `$RC`.
	- Return codes: exits with the current value of `$RC` (default 0 unless changed earlier).

## Exit codes (RC)

- 0 — Success / default (no error).
- 1 — Missing operand (no arguments provided).
- 2 — Unknown operand (invalid option passed).
- 3 — Internal error: `log()` called with wrong number of arguments.
- 4 — Missing DIRECTORY for `-d|--directory` option (directory argument not provided or invalid).
- 5 — Provided DIRECTORY does not exist or is not accessible.

## Dependencies

This script requires the following external programs and shell features:

### External programs

- bash(1)
  - Used as the script interpreter (shebang `#!/usr/bin/env bash`). The script uses Bash-specific features such as `[[ ... ]]`, `local`, and `function`.
- date(1)
  - Used to generate timestamps in `log()` and `getTimestamp()` (format strings via `+FORMAT`).

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

### Usage

```text
Usage: zerg-larva.sh [OPTION]

    -d, --directory DIRECTORY   set directory to work on
    -v, --verbose               print debugging information
    -h, --help                  display this help and exit
        --version               output version information and exit
        --list-exit-codes       print the list of script exit codes and exit
```