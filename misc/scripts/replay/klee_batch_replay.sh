#!/bin/bash

## Run crete-replay in batch mode
## $1: the output folder of klee-coreutils.py
## $2: the include file that defines several macros, including:
##     CRETE_BIN_DIR: the path of crete-build/bin
##     PARSEGCOVCMD: the path to parse_gcov_coreutils.py
##     PROG_DIR: the path to the executable of programs under replay
##     LCOV_DIR: the path to the root folder of calculating coverage
##     PROGRAMS: the name of programs under replay
##     SANDBOX: the path of input sandbox (optional)

INPUT_DIR=$1
INCLUDE_FILE=$2

KLEE_REPLAY="/home/chenbo/tools/klee-1.3.0/klee/Release+Asserts/bin/klee-replay"
main()
{
    # check inputs
    if [ -z  $INPUT_DIR ]; then
        printf "Input directory is invalid ...\n"
        exit
    fi

    if [ ! -f $INCLUDE_FILE ]; then
        printf "\$INCLUDE_FILE = \"$INCLUDE_FILE\" is an invalid file ...\n"
        exit
    fi

    source $INCLUDE_FILE

    # check Macros which should be defined in $INCLUDE_FILE
    if [ ! -d  $CRETE_BIN_DIR ]; then
        printf "\$CRETE_BIN_DIR is invalid ...\n"
        exit
    fi

    if [ ! -x $PARSEGCOVCMD ]; then
        printf "\$PARSEGCOVCMD (\"$PARSEGCOVCMD\") is invalid, check \$INCLUDE_FILE (\"$INCLUDE_FILE\")\n"
        exit
    fi

    if [ ! -d $PROG_DIR ]; then
        printf "\$PROG_DIR (\"$PROG_DIR\") is invalid, check \$INCLUDE_FILE (\"$INCLUDE_FILE\")\n"
        exit
    fi

    if [ ! -d $LCOV_DIR ]; then
        printf "\$LCOV_DIR (\"$LCOV_DIR\") is invalid, check \$INCLUDE_FILE (\"$INCLUDE_FILE\")\n"
        exit
    fi

    if [ ${#PROGRAMS[@]} == 0 ]; then
        printf "\$PROGRAMS (\"$PROGRAMS\") is invalid, check \$INCLUDE_FILE (\"$INCLUDE_FILE\")\n"
        exit
    fi

    KLEE_OUT_DIR=$(readlink -m $INPUT_DIR)

    printf "Input direcotry: $KLEE_OUT_DIR\n"

    if [ ! -d  $KLEE_OUT_DIR ]; then
        printf "$KLEE_OUT_DIR does not exists\n"
        exit
    fi

    # create new folder to put result
    foldername="replay$(date +[%Y-%m-%d_%T])"
    mkdir $foldername
    cd $foldername

    printf "1. Cleanup old coverage info...\n"
    lcov --directory $LCOV_DIR --zerocounters

    printf "2. execute all test cases in folder $KLEE_OUT_DIR ...\n"
    init_sandbox=true
    SUB_FOLDERS=$KLEE_OUT_DIR/*
    for f in $SUB_FOLDERS
    do
        target_prog="not-found"
        # 2.1 scan for target executable
        for prog in $PROGRAMS
        do
            if [[ $f == */$prog ]]
            then
                if [ $target_prog != "not-found" ]; then
                    printf "[ERROR] Mutiple executables from list \"\$PROGRAMS\" matched with subfolder $f: $target_prog and $prog!\n"
                    exit
                fi

                target_prog=$prog
            fi
        done

        if [ $target_prog == "not-found" ]; then
            printf "[Warning] No executable from list \"\$PROGRAMS\" matches subfolder $f! Skip it ...\n"
            continue
        fi

        # execute all the test cases from the current subfolder with target_prog
        test_case_dir=$f

        if [ -z  $SANDBOX ]; then
            printf "Error: \$SANDBOX is empty\n"
            exit
        else
            if [ ! -d  $SANDBOX ]; then
                printf "$SANDBOX does not exists\n"
                exit
            fi
            if [ "$init_sandbox" = true ] ; then
                printf "[W/ sandbox and init_sandbox] executing $target_prog with tc from \'$test_case_dir\'...\n"
                init_sandbox=false
                $CRETE_BIN_DIR/klee-tc-replay  -k $KLEE_REPLAY           \
                                               -e $PROG_DIR/$target_prog \
                                               -t $test_case_dir         \
                                               -j $SANDBOX               \
                                               -v /home/chenbo/crete/crete-dev/front-end/guest/sandbox/env/klee-test.env \
                                               -l >> crete-coverage-progress.log
            else
                printf "[W/ sandbox and W/O init_sandbox] executing $target_prog with tc from \'$test_case_dir\'...\n"
                $CRETE_BIN_DIR/klee-tc-replay  -k $KLEE_REPLAY           \
                                               -e $PROG_DIR/$target_prog \
                                               -t $test_case_dir         \
                                               -j $SANDBOX               \
                                               -v /home/chenbo/crete/crete-dev/front-end/guest/sandbox/env/klee-test.env \
                                               -n -l >> crete-coverage-progress.log
            fi
        fi
    done

    printf "3. Parsing crete.replay.log ...\n"
    printf "Assertion failed: "
    grep -c -w "Assertion.*failed." crete.replay.log
    printf "Exception caught: "
    grep -c -w "\[crete-replay-preload\] Exception"  crete.replay.log
    printf "Signal caught: "
    grep -c -w "\[Signal Caught\]"  crete.replay.log
    printf "Replay timeout: "
    grep -c -w "Replay Timeout"  crete.replay.log

    printf "4. generating coverage report... \n"
    lcov --directory $LCOV_DIR --capture --output-file lcov.info --rc lcov_branch_coverage=1 >> lcov.log
    genhtml lcov.info -o html --function-coverage --rc lcov_branch_coverage=1 >> lcov.log

    $PARSEGCOVCMD $PROG_DIR &> result_gcov.org

    printf "5. Finished: $foldername/result_gcov.org and $foldername/html/index.html\n"
    tail -4 lcov.log
}

main
