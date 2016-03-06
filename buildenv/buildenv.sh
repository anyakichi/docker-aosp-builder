#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

shopt -s nullglob

: ${BUILDENV_CONF_DIR:=/usr/local/share/buildenv}


list_scmd()
{
    local conf

    for conf in "${BUILDENV_CONF_DIR}"/*.txt; do
        echo "$(basename ${conf} .txt)"
    done
}

expand_vars()
{
    local file="${1:--}"

    printf "cat <<EOF\n$(sed 's/\\/\\\\\\\\/g' "${file}")\nEOF" | /bin/bash
}

get_commands()
{
    local file="${1:--}" options="${2:-0}" prefix="${3:-}"

    if [[ ${options} -ne 0 ]]; then
        cmd='/^\s*(\$|\?)\s+/{s//'${prefix}'/p}'
    else
        cmd='/^\s*\$\s+/{s//'${prefix}'/p}'
    fi

    sed -nr -e :a -e '/\\$/N; s/\\\n\s*//; ta' -e "${cmd}" "${file}"
}

do_commands()
{
    local scmd="${1:-dummy}" yes="${2:-0}" options="${3:-0}"

    if [[ ${yes} -eq 0 ]]; then
        echo "$(echo ${scmd} | sed 's/^\(.\)/\U\1/') commands:"
        echo
        expand_vars "${BUILDENV_CONF}" | get_commands - ${options} '  $ '
        echo
        read -p "Continue? ($(basename "$0") -h for details) [Y/n] "
        if [[ ! ${REPLY:-y} =~ ^([Yy][Ee][Ss]|[Yy])$ ]]; then
            exit 0
        fi
    fi

    expand_vars "${BUILDENV_CONF}" \
      | get_commands - ${options} \
      | awk '{ s=$0; gsub(/\\/, "\\\\"); gsub(/"/, "\\\"");
               print "echo \"==> " $0 "\""; print s " || exit 1" }' \
      | /bin/bash
}

usage()
{
    local status=${1:-1} msg=${2:-} expand=${3:-1}
    local cmd=$(basename "$0") scmd

    if [[ ! ${msg} ]]; then
        echo "usage: ${cmd} init"
        for scmd in $(list_scmd); do
            echo "       ${cmd} ${scmd} [args]"
        done
    else
        echo "usage: ${cmd} ${msg}"
        echo
        if [[ ${expand} -ne 0 ]]; then
            grep -v '^\s*#' "${BUILDENV_CONF}" | expand_vars -
        else
            grep -v '^\s*#' "${BUILDENV_CONF}"
        fi
    fi

    exit ${status}
}

main_init()
{
    local cmd=$(basename "$0")

    if [[ $# -ne 0 ]]; then
        echo "usage: ${cmd} init"
        exit 1
    fi

    : ${BUILDENV_ALIAS:=1}

    if [[ ${BUILDENV_ALIAS} -eq 0 ]]; then
        exit 0
    fi

    for scmd in $(list_scmd); do
        if [[ ${BUILDENV_ALIAS} -eq 1 ]] || ! type ${scmd} >/dev/null 2>&1; then
            echo "alias ${scmd}='${cmd} ${scmd}';"
        fi
    done
}

main_generic()
{
    local scmd=$1
    shift

    local xflag=0 yflag=0

    usage="${scmd} [-Hhxy]"
    while getopts "Hhxy" opt; do
        case $opt in
            H)
                usage 0 "${usage}" 0
                ;;
            h)
                usage 0 "${usage}"
                ;;
            x)
                xflag=1
                ;;
            y)
                yflag=1
                ;;
            \?)
                usage 1 "${usage}"
                ;;
        esac
    done

    shift $((OPTIND - 1))

    if [[ $# -ne 0 ]]; then
        usage 1 "${usage}"
    fi

    do_commands "${scmd}" $yflag $xflag
}

main_extract()
{
    local fflag=0 xflag=0 yflag=0

    usage="extract [-Hfhxy]"
    while getopts "Hfhxy" opt; do
        case $opt in
            H)
                usage 0 "${usage}" 0
                ;;
            f)
                fflag=1
                ;;
            h)
                usage 0 "${usage}"
                ;;
            x)
                xflag=1
                ;;
            y)
                yflag=1
                ;;
            \?)
                usage 1 "${usage}"
                ;;
        esac
    done

    shift $((OPTIND - 1))

    if [[ $# -ne 0 ]]; then
        usage 1 "${usage}"
    fi

    if [[ $fflag -eq 0 && -n "$(ls -A)" ]]; then
        echo "Target directory is not empty."
        read -p "Continue? [y/N] "
        if [[ ! $REPLY =~ ^([Yy][Ee][Ss]|[Yy])$ ]]; then
            exit 0
        fi
    fi

    do_commands extract $yflag $xflag
}

main()
{
    if [[ $# -eq 0 ]]; then
        usage 1
    fi

    scmd=$1
    : ${BUILDENV_CONF:=${BUILDENV_CONF_DIR}/${scmd}.txt}

    if [[ ${scmd} != init && ! -e ${BUILDENV_CONF} ]]; then
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
