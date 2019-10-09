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


while :; do
    found=0
    read -p "Search for student: " name
    students=""
    num=0
    students=$(grep -l "$name" "$TARGET"/*/*.txt | while IFS= read file; do
                    if [ "$(basename $file)" != "symbol_stat.txt" ]; then
                        username=$(basename $file)
                        username=${username%.*}
                        grep "Name: " $file | head -n 1 | sed -e "s/Name: /[$num] /"
                        num=$(($num + 1))
                    fi
               done)
    echo "$students"
    num=$(echo "$students" | wc -l)
    if [ $num -gt 0 ]; then
        student=-1
        if [ $num -gt 1 ]; then
            student="false"
            choice=-2
            $student
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
                students=$(echo -n "$students" | head -n $(($choice + 1)) | tail -n 1)
                num=1
            fi
        fi

        if [ $num -eq 1 ]; then
            fullname=$(echo -n "$students" | sed -e 's/\[[0-9]*\] //')
            student=$(echo -n "$fullname" | grep -Eo '\(.+\)' | sed -e 's/[()]//g')
            STUDENT_DIR="$TARGET"/"$student"
            key="y"
            while [ "$key" != "q" ]; do
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
                read -n1 -r -s key
                key=${key,,}
                case "$key" in
                   e)
                       if [ -f "$STUDENT_DIR"/eval.log ]; then
                           less "$STUDENT_DIR"/eval.log
                       else
                           echo "Could not find eval.log"
                       fi
                   ;;
                   x)
                       if [ -f "$STUDENT_DIR"/exec.log ]; then
                           less "$STUDENT_DIR"/exec.log
                       else
                           echo "Could not find exec.log"
                       fi
                       ;;
                   d)
                       if [ $(ls $STUDENT_DIR/doc | wc -l) -gt 0 ]; then
                           find "$STUDENT_DIR"/doc -type f | while IFS= read file; do
                               echo $file
                               read
                               xdg-open $file >/dev/null 2>/dev/null
                           done
                       else
                           echo "Could not find any documentation"
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
