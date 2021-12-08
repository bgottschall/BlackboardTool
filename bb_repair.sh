#!/usr/bin/env bash

PLAGIARISM_DIR='plag_check'

help() {
echo "$(basename $0) [options] <folder> <rapair-template>

Options:
    -h, --help                 this help page"
}

error() {
    while [ $# -gt 0 ]; do
        echo "$1" >&2
        shift
    done
    exit 1
}

SHORT=hf
LONG=help,force


PARSED=$(getopt --options $SHORT --longoptions $LONG --name "$0" -- "$@")

if [ $? -ne 0 ]; then
    help
    exit
fi

eval set -- "$PARSED"

FORCE=0


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

if [ $# -lt 2 ]; then
    error "ERROR: not enough arguments!" "$(help)"
fi

TARGET="$1"
shift
REPAIR="$1"
shift

if [ ! -d "$TARGET" ]; then
    error "Folder '$TARGET' does not exist!"
fi
if [ ! -d "$REPAIR" ]; then
    error "Folder '$REPAIR' does not exist!"
fi
if [ ! -f "$REPAIR"/repair ]; then
    error "Repair descriptor '$REPAIR/repair' not found!"
fi

students=""
for student in $TARGET/*; do
    if [ -d "$student"/raw ]; then
        students="$students $(basename $student)"
    fi
done

cat "$REPAIR"/repair | while IFS= read line; do
    CMD=$(echo "$line" | cut -c -1)
    WHAT=$(echo "$line" | cut -c 3-)
    TERMINATE=0
    if [ "$CMD" == "D" ]; then
        for student in $students; do
            find "$TARGET"/"$student"/ -iname "$WHAT" -exec rm -rv {} \;
        done
    elif [ "$CMD" == "R" ]; then
        for student in $students; do
            requiredPath="$TARGET"/"$student"/src/"$WHAT"
            if [ ! -f "$requiredPath" ] && [ ! -d "$requiredPath" ] ; then
                echo "Required file '$requiredPath' does not exist for '$student'!"
                TERMINATE=1
            fi
        done
    elif [ "$CMD" == "E" ]; then
        for student in $students; do
            execPath="$TARGET"/"$student"/src/
            pushd $execPath >/dev/null
            $WHAT
            popd >/dev/null
        done
    elif [ "$CMD" == "S" ]; then
        structureRegex=$(echo "$REPAIR"/"$WHAT"/ | sed -e 's/[]\/$*.^[]/\\&/g')
        find "$REPAIR"/"$WHAT"/ -follow -print0 | while IFS= read -d '' element; do
            elementRelative=$(echo "$element" | sed -e "s/$structureRegex//g")
            if [ "x$elementRelative" != "x" ]; then
                for student in $students; do
                    requiredPath="$TARGET"/"$student"/src/"$elementRelative"
                    if [ ! -f "$requiredPath" ] && [ ! -d "$requiredPath" ] ; then
                        if [ -d $element ]; then
                            mkdir -v "$requiredPath"
                        else
                            cp -v "$element" "$requiredPath"
                        fi
                    fi
                done
            fi
        done
    fi
    if [ $TERMINATE -ne 0 ]; then
        exit 1
    fi
done

exit 0
