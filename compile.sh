T_STATUS=0
OUTPUT=`mono bin/tcc.exe test/Programs/Test.TAS test.asm` || EXIT_STATUS=$?
if [ ! -z "$OUTPUT" ]
then
    echo $OUTPUT
    exit $EXIT_STATUS
fi
OUTPUT=`tasm test.asm test.bc` || EXIT_STATUS=$?
if [ ! -z "$OUTPUT" ]
then
    echo $OUTPUT
    exit $EXIT_STATUS
fi
tvm test.bc test/Inputs/test.IN || EXIT_STATUS=$?
exit $EXIT_STATUS
