mono bin/tcc.exe test/Programs/Test.TAS test.asm
printf "\n"
tasm test.asm test.bc
tvm test.bc test/Inputs/test.IN 
