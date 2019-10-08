#!/usr/bin/env bash


help() {
echo "$(basename $0) [options] <folder> [students...]

Options:
    -q, --quiet                no interactive questions
    -f, --force                (re)evaluate all
    -s, --script <script>      use evaluation script
    -r, --ressource            pass ressource directory to script
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

SHORT=hqfs:r:
LONG=help,quiet,force,script:,ressource:


PARSED=$(getopt --options $SHORT --longoptions $LONG --name "$0" -- "$@")

if [ $? -ne 0 ]; then
    help
    exit
fi

eval set -- "$PARSED"

QUIET=0
FORCE=0
USESCRIPT=0
SCRIPT=""
RESDIR=""

while :; do
    case "$1" in
       -q|--quiet)
           QUIET=1
           shift
           ;;
       -f|--force)
           FORCE=1
           shift
           ;;
       -s|--script)
           USESCRIPT=1
           SCRIPT="$2"
           shift 2
           ;;
       -r|--ressource)
           RESDIR="$2"
           shift 2
           ;;
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

students=""
while [ $# -gt 0 ]; do
    students="$students $1"
    shift
done

if [ "x$students" == "x" ]; then
    for student in $TARGET/*; do
        if [ -d "$student"/raw ]; then
            students="$students $(basename $student)"
        fi
    done
fi


if [ $USESCRIPT -ne 0 ]; then
    if [ ! -f "$SCRIPT" ]; then
        error "Script '$SCRIPT' not found!"
    fi
    if [ "x$RESDIR" != "x" ] && [ ! -d "$RESDIR" ]; then
        error "Ressource directory '$RESDIR' not found!"
    fi
fi

for student in $students; do
    EVAL=$FORCE
    OUTPUT="$TARGET"/"$student"/eval.log
    if [ $EVAL -eq 0 ]; then
        if [ ! -f "$OUTPUT" ]; then
            EVAL=1
        elif grep -Eq -i '(failed)|(error)|(timeout)' "$OUTPUT"; then
            EVAL=1
        fi
    fi
    while [ $EVAL -eq 1 ]; do
        STUDENT_DIR="$TARGET"/"$student"
        RET=0
        echo "Evaluating $student..."
        echo -n "" > "$OUTPUT"
        echo "========================================================================" | tee -a "$OUTPUT"
        if [ -f "$STUDENT_DIR"/"$student".txt ]; then
            cat "$STUDENT_DIR"/"$student".txt | tee -a $OUTPUT
            echo "" | tee -a $OUTPUT
        fi
        if [ -f "$TARGET"/"$student"/symbol_stat.txt ]; then
            cat "$TARGET"/"$student"/symbol_stat.txt | tee -a $OUTPUT
            echo "" | tee -a $OUTPUT
        fi
        if [ $USESCRIPT -eq 1 ]; then
            RUN=$QUIET
            if [ $QUIET -eq 0 ]; then
                answer=$(decide "Run evaluation script?" "Yn")
                if [ "$answer" == "y" ]; then
                    RUN=1
                fi
            fi
            if [ $RUN -ne 0 ]; then
                source "$SCRIPT" "$STUDENT_DIR" "$RESDIR" | tee -a $OUTPUT
            fi
        fi
        echo "========================================================================" | tee -a $OUTPUT
        EVAL=0
        if [ $QUIET -eq 0 ]; then
            answer=$(decide "Continue with next student or repeat this one?" "Cr")
            if [ "$answer" == "r" ]; then
                EVAL=1
            fi
        fi
    done
done
