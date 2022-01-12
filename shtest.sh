make
./comp <$1
./tests/komp $1
code -d output.asm myoutput.asm
