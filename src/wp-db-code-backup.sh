#!/bin/bash

#
# Script to backup Wordpress Codebase + Database
#
# @author   Raj KB <magepsycho@gmail.com>
# @website  https://www.magepsycho.com
# @version  0.1.0

# UnComment it if bash is lower than 4.x version
shopt -s extglob

################################################################################
# CORE FUNCTIONS - Do not edit
################################################################################
#
# VARIABLES
#
_bold=$(tput bold)
_underline=$(tput sgr 0 1)
_reset=$(tput sgr0)

_purple=$(tput setaf 171)
_red=$(tput setaf 1)
_green=$(tput setaf 76)
_tan=$(tput setaf 3)
_blue=$(tput setaf 38)

#
# HEADERS & LOGGING
#
function _debug()
{
    if [[ "$DEBUG" = 1 ]]; then
        "$@"
    fi
}

function _header()
{
    printf '\n%s%s==========  %s  ==========%s\n' "$_bold" "$_purple" "$@" "$_reset"
}

function _arrow()
{
    printf '➜ %s\n' "$@"
}

function _success()
{
    printf '%s✔ %s%s\n' "$_green" "$@" "$_reset"
}

function _error() {
    printf '%s✖ %s%s\n' "$_red" "$@" "$_reset"
}

function _warning()
{
    printf '%s➜ %s%s\n' "$_tan" "$@" "$_reset"
}

function _underline()
{
    printf '%s%s%s%s\n' "$_underline" "$_bold" "$@" "$_reset"
}

function _bold()
{
    printf '%s%s%s\n' "$_bold" "$@" "$_reset"
}

function _note()
{
    printf '%s%s%sNote:%s %s%s%s\n' "$_underline" "$_bold" "$_blue" "$_reset" "$_blue" "$@" "$_reset"
}

function _die()
{
    _error "$@"
    exit 1
}

function _safeExit()
{
    exit 0
}

#
# UTILITY HELPER
#
function _seekConfirmation()
{
  printf '\n%s%s%s' "$_bold" "$@" "$_reset"
  read -p " (y/n) " -n 1
  printf '\n'
}

# Test whether the result of an 'ask' is a confirmation
function _isConfirmed()
{
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        return 0
    fi
    return 1
}


function _typeExists()
{
    if type "$1" >/dev/null; then
        return 0
    fi
    return 1
}

function _isOs()
{
    if [[ "${OSTYPE}" == $1* ]]; then
      return 0
    fi
    return 1
}

function _checkRootUser()
{
    #if [ "$(id -u)" != "0" ]; then
    if [ "$(whoami)" != 'root' ]; then
        echo "You have no permission to run $0 as non-root user. Use sudo"
        exit 1;
    fi

}

function _printPoweredBy()
{
    local mp_ascii
    mp_ascii='
   __  ___              ___               __
  /  |/  /__ ____ ____ / _ \___ __ ______/ /  ___
 / /|_/ / _ `/ _ `/ -_) ___(_-</ // / __/ _ \/ _ \
/_/  /_/\_,_/\_, /\__/_/  /___/\_, /\__/_//_/\___/
            /___/             /___/
'
    cat <<EOF
${_green}
Powered By:
$mp_ascii

 >> Store: ${_reset}${_underline}${_blue}https://www.magepsycho.com${_reset}${_reset}${_green}
 >> Blog:  ${_reset}${_underline}${_blue}https://blog.magepsycho.com${_reset}${_reset}${_green}

################################################################
${_reset}
EOF
}

################################################################################
# SCRIPT FUNCTIONS
################################################################################
function _printUsage()
{
    echo -n "$(basename "$0") [OPTION]...

Backup Wordpress Codebase + Database.
Version $VERSION

    Options:
		-bd,	--backup-db		   Backup DB
		-bc,	--backup-code	   Backup Code
        -sd,    --src-dir          Source directory (from where backup file will be created, www-dir)
        -dd,    --dest-dir         Destination directory (to where the backup file will be moved)
		-uc,	--use-mysql-config Use MySQL config file (~/.my.cnf)
        -su,    --skip-uploads     Skip wp-content/uploads folder content from code backup.
		-bn 	--backup-name      Backup filename (without extension)
        -h,     --help             Display this help and exit
        -v,     --version          Output version information and exit

    Examples:
        $(basename "$0") --backup-db --backup-code [--skip-uploads] [--use-mysql-config] --src-dir=... --dest-dir=... [--backup-name]

"
    _printPoweredBy
    exit 1
}

function checkCmdDependencies()
{
    local _dependencies=(
      wget
      cat
      basename
      mkdir
      cp
      mv
      rm
      chown
      chmod
      date
      find
      awk
      gzip
      gunzip
    )

    for cmd in "${_dependencies[@]}"
    do
        hash "${cmd}" &>/dev/null || _die "'${cmd}' command not found."
    done;
}

function processArgs()
{
    # Parse Arguments
    for arg in "$@"
    do
        case $arg in
			-bd=*|--backup-db)
                WP_BACKUP_DB=1
            ;;
            -bc=*|--backup-code)
                WP_BACKUP_CODE=1
            ;;
            -sd=*|--src-dir=*)
                WP_SRC_DIR="${arg#*=}"
            ;;
            -dd=*|--dest-dir=*)
                WP_DEST_DIR="${arg#*=}"
            ;;
			-uc|--use-mysql-config)
                WP_USE_MYSQL_CONFIG=1
            ;;
            -su|--skip-uploads)
                WP_SKIP_UPLOADS=1
            ;;
            -bn=*|--backup-name=*)
                WP_BACKUP_NAME="${arg#*=}"
            ;;
            --debug)
                DEBUG=1
                set -o xtrace
            ;;
            -h|--help)
                _printUsage
            ;;
            *)
                #_printUsage
            ;;
        esac
    done

    validateArgs
    sanitizeArgs
}

function initDefaultArgs()
{
    WP_SRC_DIR=$(pwd)
}

function sanitizeArgs()
{
    # remove trailing /
    if [[ ! -z "WP_SRC_DIR" ]]; then
        WP_SRC_DIR="${WP_SRC_DIR%/}"
    fi

    if [[ ! -z "WP_DEST_DIR" ]]; then
        WP_DEST_DIR="${WP_DEST_DIR%/}"
    fi
}


function validateArgs()
{
    ERROR_COUNT=0

    if [[ -z "$WP_BACKUP_DB" && -z "$WP_BACKUP_CODE" ]]; then
        _error "You should mention at least one of the backups: --backup-db or --backup-code"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi

    if [[ -z "$WP_SRC_DIR" ]]; then
        _error "Source directory parameter missing."
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi

    if [[ ! -z "$WP_SRC_DIR" && ! -f "$WP_SRC_DIR/wp-config.php" ]]; then
        _error "Source directory must be Wordpress root folder."
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi

    if [[ -z "$WP_DEST_DIR" ]]; then
        _error "Destination directory parameter missing."
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi

    if [[ ! -z "$WP_DEST_DIR" ]] && ! mkdir -p "$WP_DEST_DIR"; then
        _error "Unable to create destination directory."
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi

    #echo "$ERROR_COUNT"
    [[ "$ERROR_COUNT" -gt 0 ]] && exit 1
}

function sanitizeArgs()
{
    # remove trailing /
    if [[ ! -z "$WP_SRC_DIR" ]]; then
        WP_SRC_DIR="${WP_SRC_DIR%/}"
    fi

    if [[ ! -z "$WP_DEST_DIR" ]]; then
        WP_DEST_DIR="${WP_DEST_DIR%/}"
    fi
}

function prepareBackupName()
{
    if [[ -z "$WP_BACKUP_NAME" ]]; then
        #MD5=`echo \`date\` $RANDOM | md5sum | cut -d ' ' -f 1`
        DATETIME=$(date +"%Y-%m-%d-%H-%M-%S")
        WP_BACKUP_NAME="wp-backup.$DATETIME"
    fi
}

function prepareCodebaseFilename()
{
    WP_CODE_BACKUP_FILE="${WP_DEST_DIR}/${WP_BACKUP_NAME}.tar.gz"
}

function prepareDatabaseFilename()
{
    WP_DB_BACKUP_FILE="${WP_DEST_DIR}/${WP_BACKUP_NAME}.sql.gz"
}

function createDbBackup()
{
    _success "Dumping MySQL..."
    local host username password dbName

    host=$(grep DB_HOST "${WP_SRC_DIR}/wp-config.php" |cut -d "'" -f 4)
    username=$(grep DB_USER "${WP_SRC_DIR}/wp-config.php" | cut -d "'" -f 4)
    password=$(grep DB_PASSWORD "${WP_SRC_DIR}/wp-config.php" | cut -d "'" -f 4)
    dbName=$(grep DB_NAME "${WP_SRC_DIR}/wp-config.php" |cut -d "'" -f 4)

    # @todo option to skip log tables
    if [[ "$WP_USE_MYSQL_CONFIG" -eq 1 ]]
		mysqldump "$dbName" | gzip > "$WP_DB_BACKUP_FILE"
	else
		mysqldump -h "$host" -u "$username" -p"$password" "$dbName" | gzip > "$WP_DB_BACKUP_FILE"
	fi 
	
	_success "Done!"
}

function createCodeBackup()
{
    _success "Archiving Codebase..."
    declare -a EXC_PATH
    EXC_PATH[1]=./.git
    EXC_PATH[2]=./wp-content/cache
    EXC_PATH[3]=./wp-content/upgrade
    EXC_PATH[4]=./wp-config.php

    if [[ "$WP_SKIP_UPLOADS" == 1 ]]; then
        EXC_PATH[5]=./wp-content/uploads
    fi

    EXCLUDES=''
    for i in "${!EXC_PATH[@]}" ; do
        CURRENT_EXC_PATH=${EXC_PATH[$i]}
        # note the trailing space
        EXCLUDES="${EXCLUDES}--exclude=${CURRENT_EXC_PATH} "
    done

    tar -zcf "$WP_CODE_BACKUP_FILE" ${EXCLUDES} -C "${WP_SRC_DIR}" .

	_success "Done!"
}

function rotateBackups()
{
    # @todo
    # delete all but 5 recent wordpress database back-ups (files having .sql.gz extension) in backup folder.
    find "${WP_DEST_DIR}" -maxdepth 1 -name "*.sql.gz" -type f | xargs -x ls -t | awk 'NR>5' | xargs -L1 rm

    # delete all but 5 recent wordpress files back-ups (files having .tar.gz extension) in backup folder.
    find "${WP_DEST_DIR}" -maxdepth 1 -name "*.tar.gz" -type f | xargs -x ls -t | awk 'NR>5' | xargs -L1 rm
}

function printSuccessMessage()
{
    _success "Wordpress Backup Completed!"

    echo "################################################################"
    echo ""
    #echo " >> Backup Type           : ${WP_BACKUP_TYPE}"
    echo " >> Backup Source         : ${WP_SRC_DIR}"
    if [[ $WP_BACKUP_TYPE = @(db|database|all) ]]; then
        echo " >> Database Dump File    : ${WP_DB_BACKUP_FILE}"
    fi

    if [[ $WP_BACKUP_TYPE = @(codebase|code|all) ]]; then
        echo " >> Codebase Archive File : ${WP_CODE_BACKUP_FILE}"
    fi

    echo ""
    echo "################################################################"
    _printPoweredBy

}

################################################################################
# Main
################################################################################
export LC_CTYPE=C
export LANG=C

DEBUG=0
_debug set -x
VERSION="0.1.0"

WP_SRC_DIR=
WP_DEST_DIR=
WP_BACKUP_DB=0
WP_BACKUP_CODE=0
WP_USE_MYSQL_CONFIG=0
WP_SKIP_UPLOADS=0
WP_BACKUP_NAME=
WP_DB_BACKUP_FILE=
WP_CODE_BACKUP_FILE=

function main()
{
    #_checkRootUser
    checkCmdDependencies

    [[ $# -lt 1 ]] && _printUsage

    initDefaultArgs
    processArgs "$@"

    prepareBackupName
    prepareCodebaseFilename
    prepareDatabaseFilename

    if [[ "$WP_BACKUP_DB" -eq 1 ]]; then
        createDbBackup
    fi

    if [[ "$WP_BACKUP_CODE" -eq 1 ]]; then
        createCodeBackup
    fi

    printSuccessMessage

    exit 0
}

main "$@"

_debug set +x
