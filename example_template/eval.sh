#!/usr/bin/env bash

if [ $# -lt 2 ]; then
    echo "Too few arguments" >&2
    exit 1
fi

STUDENT_DIR=$(readlink -f "$1")
RESSOURCE_DIR=$(readlink -f "$2")

SOURCE_DIR=$STUDENT_DIR/src
OUTPUT_DIR=$STUDENT_DIR/out
OUTPUT_CMD=$STUDENT_DIR/exec.log

[ -f "$OUTPUT_CMD" ] && rm "$OUTPUT_CMD"
[ -d "$OUTPUT_DIR" ] && rm -Rf "$OUTPUT_DIR"
[ -f "$STUDENT_DIR"/out.tgz ] && rm "$STUDENT_DIR"/out.tgz

mkdir "$OUTPUT_DIR"

TOTALLENGTH=80
FIRST_PADDING=60
SECOND_PADDING=$(($TOTALLENGTH - $FIRST_PADDING))
LINESEP="-"

LINE=""
for i in range $(seq 1 $TOTALLENGTH); do
    LINE=${LINE}${LINESEP}
done

assignment_run() {
    TIMEOUT=15m
    TIMEFILE=$(mktemp)
    echo "/usr/bin/time --quiet -f '%e' -o ${TIMEFILE} timeout -k 10s $TIMEOUT mpirun -np $THREADS ./main -i $ITERATIONS \"$RESSOURCE_DIR\"/$INPUT \"$OUTPUT_DIR\"/$OUTPUT" >&2
    /usr/bin/time --quiet -f '%e' -o ${TIMEFILE} timeout $TIMEOUT mpirun -np $THREADS ./main -i $ITERATIONS "$RESSOURCE_DIR"/$INPUT "$OUTPUT_DIR"/$OUTPUT >&2; RET=$?
    printf "%s\n" $LINE
    printf "%-${FIRST_PADDING}s" "${THREADS} processe(s), ${ITERATIONS} iteration(s), ${INPUT} image:"
    if [ $RET -ne 0 ]; then
        if [ $RET -eq 124 ] || [ $RET -eq 137 ]; then
            printf "%${SECOND_PADDING}s\n" "TIMEOUT"
        else
            printf "%${SECOND_PADDING}s\n" "FAILED"
        fi
    else
        printf "%${SECOND_PADDING}s\n" "PASSED"
        cmp -s "$RESSOURCE_DIR"/"$OUTPUT" "$OUTPUT_DIR"/"$OUTPUT"; RET=$?
        printf "%-${FIRST_PADDING}s" "Correctness Check:"
        [ $RET -ne 0 ]  && printf "%${SECOND_PADDING}s\n" "FAILED" || { printf "%${SECOND_PADDING}s\n" "PASSED"; rm "$OUTPUT_DIR"/"$OUTPUT"; }
    fi
    printf "%-${FIRST_PADDING}s%${SECOND_PADDING}s\n" "Execution time in seconds:" $(cat $TIMEFILE)
    printf "%s\n" $LINE
    rm "$TIMEFILE"
    return $RET
}


{
    cd $SOURCE_DIR
    echo "make clean && make" >&2
    make clean >&2 && make >&2; RET=$?
    printf "%s\n" $LINE
    printf "%-${FIRST_PADDING}s" "Compiling:"
    [ $RET -ne 0 ]  && printf "%${SECOND_PADDING}s\n" "FAILED" || printf "%${SECOND_PADDING}s\n" "PASSED"
    printf "%s\n" $LINE
    [ $RET -ne 0 ] && exit 1

    if [ ! -f main ]; then
        echo "No executable found!" >&2
        return 1
    fi
    
    
    THREADS=1; ITERATIONS=1
    INPUT="simple.bmp"; OUTPUT="simple_${VARIANT}_${ITERATIONS}.bmp"
    assignment_run
   
    THREADS=2; ITERATIONS=1
    INPUT="simple.bmp"; OUTPUT="simple_${VARIANT}_${ITERATIONS}.bmp"
    assignment_run
    THREADS=13; ITERATIONS=1
    INPUT="simple.bmp"; OUTPUT="simple_${VARIANT}_${ITERATIONS}.bmp"
    assignment_run
    
    THREADS=13; ITERATIONS=1
    INPUT="weird.bmp"; OUTPUT="weird_${VARIANT}_${ITERATIONS}.bmp"
    assignment_run     

    THREADS=13; ITERATIONS=1024
    INPUT="weird.bmp"; OUTPUT="weird_${VARIANT}_${ITERATIONS}.bmp"
    assignment_run
    
    THREADS=1; ITERATIONS=1024
    INPUT="middle.bmp"; OUTPUT="middle_${VARIANT}_${ITERATIONS}.bmp"
    assignment_run

    THREADS=12; ITERATIONS=1024
    INPUT="middle.bmp"; OUTPUT="middle_${VARIANT}_${ITERATIONS}.bmp"
    assignment_run

    echo "make clean" >&2
    make clean >&2
} 2> >(tee -a $OUTPUT_CMD >&2)

rm -Rf "$STUDENT_DIR"/out
