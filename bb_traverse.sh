#!/usr/bin/env bash


help() {
echo "$(basename $0) [options] <folder>

Options:
    -h, --help                 this help page"
}

function decide() {
    [ $# -lt 2 ] && {
        echo "INTERNAL ERROR: to few parameters in decide function" >&2
        exit 1
    }

    key="_"
    keyLC="_"
    keys="$2"
    keysLC=$(echo -n "$keys" | tr '[:upper:]' '[:lower:]')
    break=0

    echo -n "$1 [$(echo -n "$2" | sed 's/./&\//g' | sed 's/\/$//')]" >&2

    while [ $break -eq 0 ]; do
        read -n1 -r -s key
        echo $key | egrep -q '[a-zA-Z]' && {
            keyLC=$(echo "$key" | tr '[:upper:]' '[:lower:]')
            echo $keysLC | grep -o "$keyLC" && break=1
        }
        [ "$key" = "" ] && echo "$keys" | egrep -q '[A-Z]' && echo "$keys" | egrep -o '[A-Z]' | tr '[:upper:]' '[:lower:]' && break=1
    done
    echo "" >&2
}

error() {
    while [ $# -gt 0 ]; do
        echo "$1" >&2
        shift
    done
    exit 1
}

SHORT=h
LONG=help


PARSED=$(getopt --options $SHORT --longoptions $LONG --name "$0" -- "$@")

if [ $? -ne 0 ]; then
    help
    exit
fi

eval set -- "$PARSED"

while :; do
    case "$1" in
       -h|--help)
           help
           exit 0
           ;;
       --)
           shift
           break
           ;;
       *)
           echo "Unknown argument: $1"
           help
           exit 1
           ;;
    esac
done

if [ $# -lt 1 ]; then
    error "ERROR: not enough arguments!" "$(help)"
fi
TARGET="$1"
shift

if [ ! -d "$TARGET" ]; then
    error "Folder '$TARGET' does not exist!"
fi

allstudents=""
for student in $TARGET/*; do
    if [ -f "${student}/$(basename ${student}).txt" ]; then
        [ "x$allstudents" == "x" ] && allstudents=$student || allstudents="$allstudents $student"
        allstudents="$allstudents $(basename $student)"
    fi
done

num=0
while :; do
    if [ $num -ne 0 ]; then
        tput clear
    fi
    read -p "Search for student: " name
    num=0
    found=""
    for student in $allstudents; do
        file="$TARGET"/"$student"/"$student".txt
        if [ -f "$file" ]; then
            fullname=$(grep "Name: " "$file" | head -n 1 | grep -i "$name" 2>/dev/null)
            if [ $? -eq 0 ]; then
                [ "x$found" == "x" ] && found=$student || found="$found $student"
                echo $fullname | sed -e "s/Name: /[$num] /"
                num=$(($num + 1))
            fi
        fi
    done
    if [ $num -gt 0 ]; then
        if [ $num -gt 1 ]; then
            choice=-2
            while [ $choice -lt 0 ] || [ $choice -ge $num ]; do
                read -p "Choose a student [-1=exit]: " choice
                if ! echo -n "$choice" | grep -qE '([0-9]+)'; then
                    choice=-2
                fi
                if [ $choice -eq -1  ]; then
                    break;
                fi
            done
            if [ $choice -ge 0 ]; then
                student=$(echo -n $found | tr ' ' '\n' | head -n $(($choice + 1)) | tail -n 1)
                num=1
            fi
        else
            student=$found
        fi

        if [ $num -eq 1 ]; then
            STUDENT_DIR="$TARGET"/"$student"
            fullname=$(grep "Name: " "${STUDENT_DIR}/${student}.txt" | head -n 1 | sed -e 's/Name: //')
            key="y"
            error=0
            while [ "$key" != "q" ]; do
                if [ $error -eq 0 ]; then
                    tput clear
                    echo "Student: $fullname"
                    echo ""
                    echo "[e] Show eval.log"
                    echo "[x] Show exec.log"
                    echo "[s] Open source"
                    echo "[d] View Documentation"
                    echo "[f] Open student folder"
                    echo "[q] Quit"
                    echo ""
                fi
                error=0
                read -n1 -r -s key
                key=${key,,}
                case "$key" in
                   e)
                       if [ -f "$STUDENT_DIR"/eval.log ]; then
                           fold -w 81 "$STUDENT_DIR"/eval.log | less
                       else
                           echo "Could not find eval.log"
                           error=1
                       fi
                   ;;
                   x)
                       if [ -f "$STUDENT_DIR"/exec.log ]; then
                           fold -w 81 "$STUDENT_DIR"/exec.log | less
                       else
                           echo "Could not find exec.log"
                           error=1
                       fi
                       ;;
                   d)
                       if [ $(ls "${STUDENT_DIR}/doc" | wc -l) -gt 0 ]; then
                           find "$STUDENT_DIR"/doc -type f -exec xdg-open {} >/dev/null 2>/dev/null \;
                       else
                           echo "Could not find any documentation"
                           error=1
                       fi
                       ;;
                   s)
                       /usr/bin/editor "$STUDENT_DIR"/src
                       ;;
                   f)
                       xdg-open "$STUDENT_DIR" >/dev/null 2>/dev/null
                       ;;
                esac
            done
        fi
    else
        echo "No Student found!"
    fi
done
