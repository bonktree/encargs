#!/bin/sh -e
# SPDX-License-Identifier: MIT

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

# Multiple empty arguments.
# Depends on printf(1) in PATH to be able to quote arguments.
TestOut ./encargs base64:cHJpbnRmACVxXG4AYSBiAGMAAGQAAABlZQA= <<EOF
'a b'
c
''
d
''
''
ee
EOF
# Unterminated last argument.
TestOut ./encargs base64:cHJpbnRmACVxXG4AZGQAAABlZQA7AGVl <<EOF
EOF
