#!/usr/bin/env bash

filetypeDoc="pdf doc txt md docx xls xlsx"
filetypeSrc="makefile c cpp h hh cu py ipynb s"
fileSrc="cmakelists.txt"



help() {
echo "$(basename $0) [options] <zip> <target>

Options:
    -f, --force                force overwrite of target directory
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
        -f|--force)
            FORCE=1
            shift
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

if [ $# -lt 2 ]; then
    error "ERROR: not enough arguments!" "$(help)"
fi

BBZIP="$1"
TARGET="$2"

if [ ! -f "$BBZIP" ]; then
    error "ERROR: $BBZIP not found" "$(help)"
fi

if [ -d "$TARGET" ] && [ $FORCE -eq 1 ]; then
    echo "Removing $TARGET..."
    read -r -p "Are you sure? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            rm -Rf "$TARGET"
            ;;
        *)
            exit 1
            ;;
    esac
fi

if [ -d "$TARGET" ]; then
    error "ERROR: $TARGET already exists!" "$(help)"
fi

filetypeDoc=" ${filetypeDoc} "
filetypeSrc=" ${filetypeSrc} "
fileSrc=" ${fileSrc} "

TMPDIR=$(mktemp -d)
[ "x$TMPDIR" == "x" ] || [ ! -d "$TMPDIR" ] && error "ERROR: could not create temporary directory!"

unzip -qq "$BBZIP" -d "$TMPDIR" || { rm -Rf "$TMPDIR"; error "ERROR: could not extract $BBZIP"; }


mkdir -p "$TARGET" || { rm -Rf "$TMPDIR"; error; }

for i in "$TMPDIR"/*.txt; do
    USERNAME=$(grep -Eo '^(Name|Navn):.+\(.+\)' "$i" | head -n 1 | sed 's/.*(//' | sed 's/).*//')
    if [ "x$USERNAME" != "x" ]; then
        BASE=${i%.txt}
        SRCEXISTS=0
        echo "Processing $USERNAME..."
        mkdir -p "$TARGET"/"$USERNAME" || { rm -Rf "$TMPDIR"; error; }
        mkdir -p "$TARGET"/"$USERNAME"/raw || { rm -Rf "$TMPDIR"; error; }
        mkdir -p "$TARGET"/"$USERNAME"/doc || { rm -Rf "$TMPDIR"; error; }
        mkdir -p "$TARGET"/"$USERNAME"/src || { rm -Rf "$TMPDIR"; error; }
        cp "$i" "$TARGET"/"$USERNAME"/"$USERNAME".txt || { rm -Rf "$TMPDIR"; error; }
        for j in "$BASE"*; do
            if [ "$i" != "$j" ]; then
                cp "$j" "$TARGET"/"$USERNAME"/raw/"${j#"${BASE}_"}" || { rm -Rf "$TMPDIR"; error; }
            fi
        done

        if [ $(ls "$TARGET"/"$USERNAME"/raw/ | wc -l) -ne 0 ]; then
            for file in "$TARGET"/"$USERNAME"/raw/*; do
                filename=$(basename "$file")
                filename=${filename,,}
                fileext=${filename##*.}
                EXTRACTED=0
                EXTRACTDIR=$(mktemp -d)
                if [ "$fileext" == "tar" ] || [ "$fileext" == "gz" ] || [ "$fileext" == "tgz" ] || [ "$fileext" == "xz" ]; then
                    tar xf "$file" -C "$EXTRACTDIR"
                    EXTRACTED=1
                elif [ "$fileext" == "7z" ]; then
                    7za x "$file" -o"$EXTRACTDIR" >/dev/null
                    EXTRACTED=1
                elif [ "$fileext" == "zip" ] || [ "$fileext" == "7z" ]; then
                    7za x "$file" -o"$EXTRACTDIR" >/dev/null
                    EXTRACTED=1
                elif [ "$fileext" == "rar" ]; then
                    unrar x "$file" "$EXTRACTDIR" >/dev/null
                    EXTRACTED=1
                elif $(echo -n "${fileSrc}" | grep -qv " ${file} ") && $(echo -n "${filetypeDoc}" | grep -q " ${fileext} "); then
                    cp -u "$file" "$TARGET"/"$USERNAME"/doc/
                elif $(echo -n "${fileSrc}" | grep -q " ${file} ") || $(echo -n "${filetypeSrc}" | grep -q " ${fileext} "); then
                    cp -u "$file" "$TARGET"/"$USERNAME"/src/
                    SRCEXISTS=1
                fi

                if [ $EXTRACTED -eq 1 ]; then
                    find "$EXTRACTDIR" -type d -name "__MACOSX" -exec rm -Rf {} \; >/dev/null 2>/dev/null
                    find "$EXTRACTDIR" -type f -print0 | while IFS= read -r -d '' filefile; do
                        filefilename=$(basename "$filefile")
                        filefilename=${filefilename,,}
                        extext=${filefilename##*.}
                        if $(echo -n "${fileSrc}" | grep -qv " ${filefilename} ") && $(echo -n "${filetypeDoc}" | grep -q " ${extext} "); then
                            mv -vu "$filefile" "$TARGET"/"$USERNAME"/doc/
                        fi
                    done
                    if [ $SRCEXISTS -eq 0 ]; then
                        while [ $(ls "$EXTRACTDIR" | wc -l) -eq 1 ] && [ -d "$EXTRACTDIR"/* ]; do
                            EXTRACTDIR="$EXTRACTDIR"/"$(ls "$EXTRACTDIR")"
                        done
                        cp -Ru "$EXTRACTDIR"/* "$TARGET"/"$USERNAME"/src/
                        SRCEXISTS=1
                    fi

                fi
 
                rm -Rf "$EXTRACTDIR"
            done

            if [ $SRCEXISTS -eq 0 ]; then
                echo "WARNING: no source files detected"
            fi
        else
            echo "WARNING: nothing was submited, look into description"
        fi
    fi
done


rm -Rf $TMPDIR
