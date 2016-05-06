#!/bin/bash


VER=1.0
BAS=`tput sgr0`
BOL=`tput bold`
COL=`tput setaf 2`


function version()
{
    echo -e "\n  ${BOL}FFiller $VER${BAS} - Creates files of arbitrary size or rewrites with the same source size.\n"
}


function usage()
{
    # display version
    version

    echo -e "\n  ${BOL}Usage: ${BAS} $0 [-f <file>] -s <size> [-t zero/random] -y -v [<file> <file2> ..]\n
          The file size argument is mandatory. See --size option.
          ${COL}example${BAS}: $0 -s 10g -t zero file1 file2 file3"

    echo -e "\n  --help: -h\n
          Display this message.\n"

    echo -e "\n  --file: [-f <file>]\n
          With -f option, all filenames at the end will be ignored.
          Default name: 'out'.
          ${COL}example${BAS}: $0 -f file -s 10m\n"

    echo -e "\n  --size: -s <size>\n
          The file size argument is ${BOL}mandatory${BAS} and can be expressed in K, M or G.
          ${COL}example:${BAS} $0 -s 10m\n"

    echo -e "\n  --type: [-t zero/random]\n
          The file can be filled with /dev/zero or /dev/urandom
          Default: empty file.
          ${COL}example${BAS}: $0 -f file -s 10m -t random\n"

    echo -e "\n  --verbose: -v\n
          Display transfer stats.\n"

    echo -e "\n  --yall: -y\n
          Skips all rewriting confirmations.\n"

    echo -e "\n  --version.\n
          Display version.\n\n"
}


function size()
{
    shopt -s nocasematch
    case "${1: -1:1}" in
        K) mult=$((1<<10)); ;;
        M) mult=$((1<<20)); ;;
        G) mult=$((1<<30)); ;;
        [0-9]) mult=1; ;;
        *) return 1; ;;
    esac
    base=${1%[^0-9]}
    [ -z "${base//[0-9]}" ] && echo $((base * mult))
}


function fill()
{
    if [[ "$OSTYPE" == darwin* ]]; then
        SZ_SPACE="`df -Hb . | tail -1 | awk '{print $4}'`"
    else
        SZ_SPACE="`df . -B1 | tail -1 | awk '{print $4}'`"
    fi

    if [[ "$SZ_SPACE" -lt "$OPT_S" ]]; then
        echo -e "You do not have enough space to create the file.\nExit."
        exit 1
    fi

    if [ "$OPT_T" == "random" ] || [ "$OPT_T" == "RANDOM" ]; then
        TYPE="if=/dev/urandom"
        OUTP="of=$OPT_F"
        SIZE="bs=$OPT_S"
        COUNT="count=1"
        FILL="filling $OPT_F from /dev/urandom"

    elif [ "$OPT_T" == "zero" ] || [ "$OPT_T" == "ZERO" ]; then
        TYPE="if=/dev/zero"
        OUTP="of=$OPT_F"
        SIZE="bs=$OPT_S"
        COUNT="count=1"
        FILL="filling $OPT_F from /dev/zero"

    else
        TYPE=""
        OUTP="of=$OPT_F"
        SIZE="bs=1"
        COUNT="count=0"
        SEEK="seek=$OPT_S"
        FILL="filling $OPT_F default"
    fi

    if ! [[ "$OPT_Y" == "true" ]] && [ -e "$OPT_F" ]; then
        read -p "file $OPT_F exists. Do you want to replace it? [y/N]: " ANS

        if [ "$ANS" == "y" ] || [ "$ANS" == "Y" ]; then
            OUTP=$(dd $TYPE "$OUTP" "$SIZE" "$COUNT" $SEEK 2>&1)
            REFILL="and overwriting all data."

            if [[ $? == 0 ]]; then
                echo "$FILL $REFILL"

                if [[ "$OPT_V" == "true" ]]; then
                    echo "$OUTP"
                fi
            else echo -e "Some error has occured.\nExit."
                 return 1
            fi
        else
            echo "Ignored."
        fi
    else
        OUTP=$(dd $TYPE "$OUTP" "$SIZE" "$COUNT" $SEEK 2>&1)
        if [[ $? == 0 ]]; then
            echo "$FILL $REFILL";

            if [[ "$OPT_V" == "true" ]]; then
                echo "$OUTP"
            fi
        else
            echo -e "Some error has occured.\nExit."
            return 1
        fi
    fi
}


function main()
{
    # no args, display usage
    if [ "$#" -le "0" ]; then
	    usage
	    exit 1
    fi

    if [[ "$1" = "--help" || "$1" = "-h" ]]; then
	    usage
	    exit 0
    fi

    if [[ "$1" = "--version" ]]; then
	    version
	    exit 0
    fi

    while :
    do
        case $1 in
            -f | --file    ) OPT_F=$2
                             if [ "$OPT_F" == "" ]; then
                                 echo "Invalid option '$1'. You must specify a filename."
                                 exit 1
                             fi
                             shift 2 ;;

            -s | --size    ) OPT_S="$(size $2)"
                             if [ $? == 1 ] || [ "$OPT_S" == "0" ] ; then
                                 echo "Invalid size '$2'. See --help option."
                                 exit 1
                             fi
                             shift 2 ;;

            -t | --type    ) OPT_T=$2
                             type=(zero ZERO random RANDOM)
                             if ! [[ "${type[@]}" =~ "${OPT_T}" ]]; then
                                 echo "Invalid option '$1'. You must specify a valid type."
                                 exit 1
                             fi
                             shift 2 ;;

            -v | --verbose ) OPT_V="true"
                             shift ;;

            -y | --yall    ) OPT_Y="true"
                             shift ;;

            -*             ) echo "Invalid option '$1'. Interrupted."
                             exit 1 ;;

            *              ) break ;;
        esac
    done

    if [ -z "$OPT_S" ]; then
        echo -e "You must specify the file size at least.\nInterrupted."
        exit 1
    fi

    if [ -z "$OPT_F" ]; then
        if [[ "$@" == "" ]]; then
            OPT_F="out"
            fill
            if [ $? == 1 ]; then exit 1; fi
            echo "Done."
            exit 0
        fi

        if [[ "$@" != "" ]]; then
            for i in "$@"
            do
                OPT_F="$i"
                echo -e "\nProcessing: $i"
                if [ -d "$OPT_F" ]; then  # is a directory
                    echo "$OPT_F is a directory. Ignored.."
                    continue
                fi
                fill
                if [ $? == 1 ]; then exit 1; fi
            done
            echo "Done."
            exit 0
        fi
    fi

    if [[ ! -z "$OPT_F" ]]; then
        if [[ "$@" != "" ]]; then
            echo "You have selected -f option. All filenames at the end will be ignored."
        fi
        if [ -d "$OPT_F" ]; then
            echo -e "$OPT_F is a directory. Ignored.\nDone."
            exit 1
        fi
        fill
        if [ $? == 1 ]; then exit 1; fi
        echo -e "Done."
        exit 0
    fi
    exit 0
}


main "$@"
