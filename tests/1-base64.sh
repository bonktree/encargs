#!/bin/sh -e

tst_no=0
TestOut_PATH="."
TestErr_PATH="."

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

TestErr ./encargs dHJ1ZQBhYQBiYgA <<EOF
./encargs: Missing or unknown operand encoding.
EOF
TestErr ./encargs printable:dHJ1ZQBhYQBiYgA <<EOF
./encargs: Missing or unknown operand encoding.
EOF
# Our decoder always produces a null-terminated string,
# so we do not detect empty operands.
TestErr ./encargs base64: <<EOF
./encargs: exec: No such file or directory
EOF
TestErr ./encargs base64:1 <<EOF
./encargs: Unexpected end-of-string at input byte 1.
EOF
TestErr ./encargs base64:1: <<EOF
./encargs: Invalid input byte 1.
EOF
TestErr ./encargs base64:1A <<EOF
./encargs: Unexpected end-of-string at input byte 2.
EOF
TestErr ./encargs base64:: <<EOF
./encargs: Invalid input byte 0.
EOF
TestErr ./encargs base64::t <<EOF
./encargs: Invalid input byte 0.
EOF
TestErr ./encargs base64:= <<EOF
./encargs: Invalid input byte 0.
EOF
TestErr ./encargs base64:==== <<EOF
./encargs: Invalid input byte 0.
EOF
TestErr ./encargs base64:====== <<EOF
./encargs: Invalid input byte 0.
EOF
TestErr ./encargs base64:=t <<EOF
./encargs: Invalid input byte 0.
EOF
TestErr ./encargs base64:A <<EOF
./encargs: Unexpected end-of-string at input byte 1.
EOF
TestErr ./encargs base64:A= <<EOF
./encargs: Invalid input byte 1.
EOF
TestErr ./encargs base64:A=== <<EOF
./encargs: Invalid input byte 1.
EOF
TestErr ./encargs base64:AA <<EOF
./encargs: Unexpected end-of-string at input byte 2.
EOF
# Ensure '3' is rejected as third byte in 4-byte block,
# since it is a non-canonical representation of `AA0='.
TestErr ./encargs base64:AA3= <<EOF
./encargs: Invalid input byte 2.
EOF
TestErr ./encargs base64:AA==A <<EOF
./encargs: Trailing rubbish at input byte 4.
EOF
TestErr ./encargs base64:AA==Ayg= <<EOF
./encargs: Trailing rubbish at input byte 4.
EOF
TestErr ./encargs base64:AA=A <<EOF
./encargs: Invalid input byte 3.
EOF
TestErr ./encargs base64:AA=O <<EOF
./encargs: Invalid input byte 3.
EOF
TestErr ./encargs base64:AAA <<EOF
./encargs: Unexpected end-of-string at input byte 3.
EOF
# For this and the following tests with correct input,
# ensure the input is indeed considered correct, and
# is passed to execv(3).
# It is also normal that we cannot execute this in the test runner.
TestErr ./encargs base64:AAAA <<EOF
./encargs: exec: No such file or directory
EOF
TestErr ./encargs base64:ARRR <<EOF
./encargs: Truncated command line.
EOF
TestErr ./encargs base64:ARRR: <<EOF
./encargs: Invalid input byte 4.
EOF
TestErr ./encargs base64:AR!R: <<EOF
./encargs: Invalid input byte 2.
EOF
TestErr ./encargs base64:ARRRR <<EOF
./encargs: Unexpected end-of-string at input byte 5.
EOF
TestErr ./encargs base64:ARRRg: <<EOF
./encargs: Invalid input byte 5.
EOF
TestErr ./encargs base64:ARRRgg: <<EOF
./encargs: Invalid input byte 6.
EOF
TestErr ./encargs base64:ARRRggg: <<EOF
./encargs: Invalid input byte 7.
EOF
TestErr ./encargs base64:ARRRgggg: <<EOF
./encargs: Invalid input byte 8.
EOF
TestErr ./encargs base64:AW: <<EOF
./encargs: Invalid input byte 2.
EOF
TestErr ./encargs base64:AWW: <<EOF
./encargs: Invalid input byte 3.
EOF
TestErr ./encargs base64:AWWW: <<EOF
./encargs: Invalid input byte 4.
EOF
TestErr ./encargs base64:Ag= <<EOF
./encargs: Unexpected end-of-string at input byte 3.
EOF
TestErr ./encargs base64:Ag== <<EOF
./encargs: Truncated command line.
EOF
TestErr ./encargs base64:Ag====== <<EOF
./encargs: Trailing rubbish at input byte 4.
EOF
TestErr ./encargs base64:TrDa==== <<EOF
./encargs: Invalid input byte 4.
EOF
TestErr ./encargs base64:TrDaAg====== <<EOF
./encargs: Trailing rubbish at input byte 8.
EOF
TestErr ./encargs base64:b <<EOF
./encargs: Unexpected end-of-string at input byte 1.
EOF
TestErr ./encargs base64:b3 <<EOF
./encargs: Unexpected end-of-string at input byte 2.
EOF
TestErr ./encargs base64:b: <<EOF
./encargs: Invalid input byte 1.
EOF
TestErr ./encargs base64:bnZpb <<EOF
./encargs: Unexpected end-of-string at input byte 5.
EOF
TestErr ./encargs base64:bnZpbQAtLWVtYmVkAC0tY21kAGxldCAmcnRwLj0nLC91c3IvYmluLy4uL <<EOF
./encargs: Unexpected end-of-string at input byte 57.
EOF
TestErr ./encargs base64:bg <<EOF
./encargs: Unexpected end-of-string at input byte 2.
EOF
TestErr ./encargs base64:br <<EOF
./encargs: Unexpected end-of-string at input byte 2.
EOF
TestErr ./encargs base64:bt <<EOF
./encargs: Unexpected end-of-string at input byte 2.
EOF
TestErr ./encargs base64:bz <<EOF
./encargs: Unexpected end-of-string at input byte 2.
EOF
TestErr ./encargs base64:bz== <<EOF
./encargs: Invalid input byte 1.
EOF
TestErr ./encargs base64:r06= <<EOF
./encargs: Invalid input byte 2.
EOF
TestErr ./encargs base64:r0g= <<EOF
./encargs: Truncated command line.
EOF
TestErr ./encargs base64:r3 <<EOF
./encargs: Unexpected end-of-string at input byte 2.
EOF
TestErr ./encargs base64:r33 <<EOF
./encargs: Unexpected end-of-string at input byte 3.
EOF
TestErr ./encargs base64:r33+ <<EOF
./encargs: Truncated command line.
EOF
TestErr ./encargs base64:r333 <<EOF
./encargs: Truncated command line.
EOF
TestErr ./encargs base64:r33= <<EOF
./encargs: Invalid input byte 2.
EOF
TestErr ./encargs base64:r36= <<EOF
./encargs: Invalid input byte 2.
EOF
TestErr ./encargs base64:r3:= <<EOF
./encargs: Invalid input byte 2.
EOF
# In our implementation, invalid bytes before padding are found before reading
# further.
TestErr ./encargs base64:r3= <<EOF
./encargs: Invalid input byte 1.
EOF
TestErr ./encargs base64:r3=9 <<EOF
./encargs: Invalid input byte 1.
EOF
TestErr ./encargs base64:r3=99 <<EOF
./encargs: Invalid input byte 1.
EOF
TestErr ./encargs base64:r3== <<EOF
./encargs: Invalid input byte 1.
EOF
TestErr ./encargs base64:r3\\= <<EOF
./encargs: Invalid input byte 2.
EOF
TestErr ./encargs base64:r3\\=99 <<EOF
./encargs: Invalid input byte 2.
EOF
TestErr ./encargs base64:r::::::t:= <<EOF
./encargs: Invalid input byte 1.
EOF
TestErr ./encargs base64:r:t:= <<EOF
./encargs: Invalid input byte 1.
EOF
TestErr ./encargs base64:r= <<EOF
./encargs: Invalid input byte 1.
EOF
TestErr ./encargs base64:r== <<EOF
./encargs: Invalid input byte 1.
EOF
TestErr ./encargs base64:rA== <<EOF
./encargs: Truncated command line.
EOF
TestErr ./encargs base64:rB6= <<EOF
./encargs: Invalid input byte 2.
EOF
TestErr ./encargs base64:rBg= <<EOF
./encargs: Truncated command line.
EOF
TestErr ./encargs base64:rD/= <<EOF
./encargs: Invalid input byte 2.
EOF
TestErr ./encargs base64:rI== <<EOF
./encargs: Invalid input byte 1.
EOF
TestErr ./encargs base64:rJ== <<EOF
./encargs: Invalid input byte 1.
EOF
TestErr ./encargs base64:rQ+= <<EOF
./encargs: Invalid input byte 2.
EOF
TestErr ./encargs base64:rQ= <<EOF
./encargs: Unexpected end-of-string at input byte 3.
EOF
TestErr ./encargs base64:rQ=7 <<EOF
./encargs: Invalid input byte 3.
EOF
TestErr ./encargs base64:rQ== <<EOF
./encargs: Truncated command line.
EOF
TestErr ./encargs base64:rQ==6141 <<EOF
./encargs: Trailing rubbish at input byte 4.
EOF
TestErr ./encargs base64:rQ====== <<EOF
./encargs: Trailing rubbish at input byte 4.
EOF
TestErr ./encargs base64:rQAA <<EOF
./encargs: exec: No such file or directory
EOF
TestErr ./encargs base64:rQAAAA <<EOF
./encargs: Unexpected end-of-string at input byte 6.
EOF
TestErr ./encargs base64:rQAAAA== <<EOF
./encargs: exec: No such file or directory
EOF
TestErr ./encargs base64:rQAAAA=== <<EOF
./encargs: Trailing rubbish at input byte 8.
EOF
TestErr ./encargs base64:rQAAAAAA <<EOF
./encargs: exec: No such file or directory
EOF
TestErr ./encargs base64:rQAAAAAAAA <<EOF
./encargs: Unexpected end-of-string at input byte 10.
EOF
TestErr ./encargs base64:rQg= <<EOF
./encargs: Truncated command line.
EOF
TestErr ./encargs base64:rY== <<EOF
./encargs: Invalid input byte 1.
EOF
TestErr ./encargs base64:rbg= <<EOF
./encargs: Truncated command line.
EOF
TestErr ./encargs base64:/t:= <<EOF
./encargs: Invalid input byte 2.
EOF
TestErr ./encargs base64:/t= <<EOF
./encargs: Invalid input byte 1.
EOF
TestErr ./encargs base64://// <<EOF
./encargs: Truncated command line.
EOF
