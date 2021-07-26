#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

shopt -s nullglob


if [[ -r /etc/buildenv.conf ]]; then
    . /etc/buildenv.conf
fi

ALIASES=${ALIASES:=1}
DOTCMDS=${DOTCMDS:=}
CONFDIR=${CONFDIR:=/etc/buildenv.d}


list_scmds()
{
    ls "${CONFDIR}" | sed 's/\..*$//' | sort -u
}

get_content_of_scmd()
{
    local file newline=""

    for file in "${CONFDIR}/${1}".*; do
        if [[ -n "${newline}" ]]; then
            echo
        else
            newline="\n"
        fi
        cat "${file}"
    done
}

dotcmd_p()
{
    local pat="\\<$1\\>"

    [[ ${DOTCMDS} =~ ${pat} ]]
}

expand_vars()
{
    local input

    input="$(cat -)"

    cat <<-EOF_OUT | /bin/bash -u
	cat <<EOF
	$(echo "${input}" | sed -r 's/\\(\$)|(\\|`)/\\\1\2/g')
	EOF
	EOF_OUT
}

select_commands()
{
    local epat="${1:-\$}" input

    [[ ${2+x} ]] && input="${2}" || input="$(cat -)"

    cmd='/^\s*('${epat}')\s+/{s///p}'

    echo "${input}" | sed -nr -e :a -e '/\\$/N; s/\s*\\\n\s*/ /; ta' -e "${cmd}"
}

exec_commands()
{
    local input

    [[ ${1+x} ]] && input="${1}" || input="$(cat -)"

    /bin/bash <(echo "${input}" \
      | awk '{ s=$0; gsub(/\\/, "\\\\"); gsub(/"/, "\\\"");
               print "echo \"==> " $0 "\" >&2"; print s " || exit 1" }')
}

ask_exec_commands()
{
    local scmd="${1:-dummy}" input="${2:-}"

    echo "${scmd^} commands:"
    echo
    echo "${input}" | sed 's/^/  $ /'
    echo

    read -rp "Continue? ($(basename "$0") ${scmd} -h for details) [Y/n] "
    if [[ ${REPLY:-y} =~ ^([Yy][Ee][Ss]|[Yy])$ ]]; then
        exec_commands "${input}"
    fi
}

usage()
{
    local status=${1:-1} scmd=${2:-}
    local cmd

    cmd="$(basename "$0")"

    if [[ ! ${scmd} ]]; then
        echo "usage: ${cmd} init"
        for scmd in $(list_scmds); do
            echo "       ${cmd} ${scmd} [args]"
        done
    else
        case "${scmd}" in
            extract)
                echo "usage: ${cmd} ${scmd} [-Ddfhpxy]"
                ;;
            *)
                echo "usage: ${cmd} ${scmd} [-Ddhpxy]"
                ;;
        esac
    fi

    exit "${status}"
}

print_alias()
{
    local scmd="$1" type="${2:-}" pat="\\<${1}\\>"

    if [[ ${ALIASES} == 1 ]] || \
       ([[ ${ALIASES} == 2 ]] && ! type "${scmd}" >/dev/null 2>&1) || \
       [[ ${ALIASES} =~ ${pat} ]];
    then
        if [[ ${type} == "source" ]]; then
            echo "alias ${scmd}='. <(${cmd} ${scmd})'"
        else
            echo "alias ${scmd}='${cmd} ${scmd}'"
        fi
    fi
}

main_init()
{
    local cmd scmd

    cmd="$(basename "$0")"

    if [[ $# -ne 0 ]]; then
        usage 1
    fi

    if [[ ${ALIASES} == 0 ]]; then
        return 0
    fi

    for scmd in $(list_scmds); do
        if dotcmd_p "${scmd}"; then
            print_alias "${scmd}" "source"
        else
            print_alias "${scmd}" "default"
        fi
    done
}

main_generic()
{
    local scmd=$1
    shift

    local force='' epat='\$' pronly='' yes=''

    if dotcmd_p "${scmd}"; then
        pronly=yes
    fi

    while getopts "Ddfhpxy" opt; do
        case $opt in
            D)
                get_content_of_scmd "${scmd}"
                exit 0
                ;;
            d)
                get_content_of_scmd "${scmd}" | expand_vars
                exit 0
                ;;
            f)
                [[ ${scmd} != extract ]] && usage 1 "${scmd}"
                force=yes
                ;;
            h)
                usage 0 "${scmd}"
                ;;
            p)
                pronly=yes
                ;;
            x)
                epat='\$|\?'
                ;;
            y)
                yes=yes
                ;;
            \?)
                usage 1 "${scmd}"
                ;;
        esac
    done

    shift $((OPTIND - 1))

    if [[ $# -ne 0 ]]; then
        usage 1 "${scmd}"
    fi

    commands=$(get_content_of_scmd "${scmd}" \
                | expand_vars \
                | select_commands "${epat}")

    if [[ -z "${commands}" ]]; then
        exit 0
    fi

    if [[ ${pronly} ]]; then
        echo "${commands}"
        exit 0
    fi

    if [[ ${scmd} == extract && -n "$(ls -A)" && ! ${force} ]]; then
        echo "Target directory is not empty."
        read -rp "Continue? [y/N] "
        if [[ ! ${REPLY} =~ ^([Yy][Ee][Ss]|[Yy])$ ]]; then
            exit 0
        fi
    fi

    if [[ ${yes} ]]; then
        exec_commands "${commands}"
    else
        ask_exec_commands "${scmd}" "${commands}"
    fi
}

main()
{
    if [[ $# -eq 0 ]]; then
        usage 1
    fi

    local scmd="${1}" pat="\\<${1}\\>"

    if [[ ${scmd} != init && ! $(list_scmds) =~ ${pat} ]]; then
        usage 1
    fi

    if type "main_${scmd}" >/dev/null 2>&1; then
        shift
        "main_${scmd}" "$@"
    else
        main_generic "$@"
    fi
}

main "$@"
