#!/bin/sh -e

tst_no=0
TestOut_PATH="$PATH"
TestErr_PATH="$PATH"

TestOut() {
    tst_no="$((tst_no + 1))"
    {
        /usr/bin/printf '%q, ' "$@";
        printf '\n# std out\n';
        cat
    } >exp-$tst_no.out
    {
        /usr/bin/printf '%q, ' "$@";
        printf '\n# std out\n';
    } >tst-$tst_no.out
    ret=0
    PATH="$TestOut_PATH" "$@" </dev/null >>tst-$tst_no.out 2>tst-$tst_no.err || ret=$?
    diff -u tst-$tst_no.out exp-$tst_no.out
    rm -f tst-$tst_no.out exp-$tst_no.out
}

TestErr() {
    tst_no="$((tst_no + 1))"
    {
        /usr/bin/printf '%q, ' "$@";
        printf '\n# std err\n';
        cat
    } >exp-$tst_no.err
    {
        /usr/bin/printf '%q, ' "$@";
        printf '\n# std err\n';
    } >tst-$tst_no.err
    ret=0
    PATH="$TestErr_PATH" "$@" </dev/null >/dev/null 2>>tst-$tst_no.err || ret=$?
    diff -u tst-$tst_no.err exp-$tst_no.err
    rm -f tst-$tst_no.err exp-$tst_no.err
}

TestOut ./encargs base64:'
	cHJpbnR
m	AGFyZz
og	JXNcb
gBh	IGIA
YwAA	ZAA
AAGVl	AA==
' <<EOF
arg: a b
arg: c
arg: 
arg: d
arg: 
arg: 
arg: ee
EOF
TestErr ./encargs base64:'
	cHJpbnR
m	AGFyZz
og	JXNcb
gBh	IGIA
YwAA	ZAA
AAGVl	AA==
' <<EOF
EOF
# This one has an illegal !, so we must fail with an empty standard output.
TestOut ./encargs base64:'
	cHJpbnR
m	AGFyZz
og	JXNcb
gBh	IGIA  !
YwAA	ZAA
AAGVl	AA==
' <<EOF
EOF
# This one has an illegal !, so we must fail with a correct error message.
TestErr ./encargs base64:'
	cHJpbnR
m	AGFyZz
og	JXNcb
gBh	IGIA  !
YwAA	ZAA
AAGVl	AA==
' <<EOF
./encargs: Invalid input byte 38.
EOF
TestOut ./encargs base64:'
c HJp b nRmA G         Fy  ZzogJXN cbg   BhI GI    AYwAAZAAAAGVlA   A = =  ' <<EOF
arg: a b
arg: c
arg: 
arg: d
arg: 
arg: 
arg: ee
EOF
TestErr ./encargs base64:'
c HJp b nRmA G         Fy  ZzogJXN cbg   BhI GI    AYwAAZAAAAGVlA   A = =  ' <<EOF
EOF
TestErr ./encargs base64:'
c HJp b nRmA G         Fy  !!!!JXN cbg   BhI GI    AYwAAZAAAAGVlA   A = =  ' <<EOF
./encargs: Invalid input byte 28.
EOF
# A correct program written in Whitespace language.
# CC-BY-SA 4.0 applies to its text.
# That program is effectively an empty operand, see 1-base64 suite, test 3.
TestOut ./encargs base64:"$(tr -Cd ' \n\r\t' <<EOArg
S S S T	S S T	S S S L:Push_+1001000=72='H'_onto_the_stack
T	L
S S :Output_'H';_S S S T	T	S S T	S T	L:Push_+1100101=101='e'_onto_the_stack
T	L
S S :Output_'e';_S S S T	T	S T	T	S S L:+1101100=108='l'
T	L
S S S S S T	T	S T	T	S S L:+1101100=108='l'
T	L
S S S S S T	T	S T	T	T	T	L:+1101111=111='o'
T	L
S S S S S T	S T	T	S S L:+101100=44=','
T	L
S S S S S T	S S S S S L:+100000=32=Space
T	L
S S S S S T	T	T	S T	T	T	L:+1110111=119='w'
T	L
S S S S S T	T	S T	T	T	T	L:+1101111=111='o'
T	L
S S S S S T	T	T	S S T	S L:+1110010=114='r'
T	L
S S S S S T	T	S T	T	S S L:+1101100=108='l'
T	L
S S S S S T	T	S S T	S S L=+1100100=100='d'
T	L
S S S S S T	S S S S T	L:+100001=33='!'
T	L
S S :Output_'!';_L
L
L:End_the_program
EOArg
)" <<EOF
EOF
# A correct program written in Whitespace language.
# CC-BY-SA 4.0 applies to its text.
# That program is effectively an empty operand, see 1-base64 suite, test 3.
TestErr ./encargs base64:"$(tr -Cd ' \n\r\t' <<EOArg
S S S T	S S T	S S S L:Push_+1001000=72='H'_onto_the_stack
T	L
S S :Output_'H';_S S S T	T	S S T	S T	L:Push_+1100101=101='e'_onto_the_stack
T	L
S S :Output_'e';_S S S T	T	S T	T	S S L:+1101100=108='l'
T	L
S S S S S T	T	S T	T	S S L:+1101100=108='l'
T	L
S S S S S T	T	S T	T	T	T	L:+1101111=111='o'
T	L
S S S S S T	S T	T	S S L:+101100=44=','
T	L
S S S S S T	S S S S S L:+100000=32=Space
T	L
S S S S S T	T	T	S T	T	T	L:+1110111=119='w'
T	L
S S S S S T	T	S T	T	T	T	L:+1101111=111='o'
T	L
S S S S S T	T	T	S S T	S L:+1110010=114='r'
T	L
S S S S S T	T	S T	T	S S L:+1101100=108='l'
T	L
S S S S S T	T	S S T	S S L=+1100100=100='d'
T	L
S S S S S T	S S S S T	L:+100001=33='!'
T	L
S S :Output_'!';_L
L
L:End_the_program
EOArg
)" <<EOF
./encargs: Empty command line.
EOF
