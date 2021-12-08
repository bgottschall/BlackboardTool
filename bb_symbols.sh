#!/usr/bin/env bash


help() {
echo "$(basename "$0") [options] <folder>

Options:
    --compare       compare only
    -c, --counters  counter file
    -h, --help      this help page"
}

error() {
    while [ $# -gt 0 ]; do
        echo "$1" >&2
        shift
    done
    exit 1
}

SHORT=hc:
LONG=help,counters,compare


PARSED=$(getopt --options $SHORT --longoptions $LONG --name "$0" -- "$@")

if [ $? -ne 0 ]; then
    help
    exit
fi

eval set -- "$PARSED"

COMPAREONLY=0
COUNTERFILE=0

while :; do
    case "$1" in
       --compare)
           COMPAREONLY=1
           shift 1
           ;;
       -c|--counters)
           COUNTERFILE="$2"
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

if [ $COMPAREONLY -eq 0 ] && [ ! -f "$COUNTERFILE" ]; then
    error "Counter file '$COUNTERFILE' does not exist!"
fi

students=""
for student in "$TARGET"/*; do
    if [ -d "$student"/raw ]; then
        students="$students $(basename "$student")"
    fi
done

if [ $COMPAREONLY -eq 0 ]; then
    for student in $students; do
        echo "Processing $student..."
        plagfile="$TARGET"/"$student"/symbol_stat.txt
        rm -f "$plagfile"; touch "$plagfile"
        if [ "$(ls "$TARGET"/"$student"/src | wc -l)" -ne 0 ]; then
            tmpfile=$(mktemp)
            cat "$COUNTERFILE" | while IFS= read -r counter; do
                grep -oih "$counter" "$TARGET"/"$student"/src -R > "$tmpfile"
                echo "${counter}: $(cat "$tmpfile" | wc -l)" >> "$plagfile"
            done
            rm "$tmpfile"
        else
            echo "WARNING: no src files detected!"
        fi
        if [ ! -s "$plagfile" ]; then
            rm "$plagfile"
        fi
    done
fi

echo "Comparing..."
tmpfile=$(mktemp)
for student in $students; do
    plagfile="$TARGET"/"$student"/symbol_stat.txt
    if [ -f "$plagfile" ]; then
        for check in $students; do
            if [ "$check" != "$student" ]; then
                checkplagfile="$TARGET"/"$check"/symbol_stat.txt
                if cmp -s "$checkplagfile" "$plagfile"; then
                    if ! grep -q "${student}${check}" "$tmpfile"; then
                        echo "${student}${check}" >> "$tmpfile"
                        echo "${check}${student}" >> "$tmpfile"
                        echo "Counters for '$student' and '$check' are the same!"
                    fi
                fi
            fi
        done
    fi
done
rm "$tmpfile"
