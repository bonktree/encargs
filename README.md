# encargs

## Synopsis

    encargs [-hV] [encoding]:[data]

## Description

This utility takes a printable-encoded operand as its only non-option argument,
decodes it and interprets the result as a NUL-separated command line to be
passed to execv(3). It leaves its standard input untouched. It is vaguely
analogous to POSIX xargs: where `xargs -0` reads word lists from standard input,
encargs decodes a single word list from its first argument, though the NUL byte
is a ___word terminator___, not a word list separator in the input of encargs.

The supported printable encodings are picked such that the encoded data is not
mangled by UNIX shell word split or various substitution and expansion passes.
As a consequence, it is much easier to pass an encargs invocation through
[shell heredocs](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_07_04),
`sh -c` arguments and ssh(1) command lines.

## Usage examples
```sh
    $ git init
    Initialized empty Git repository in /usr/src/build/.git/
    $ git add README.md
    $ printf '%s\0' git commit -m "Initial commit" | base64 -w 0
    Z2l0AGNvbW1pdAAtbQBJbml0aWFsIGNvbW1pdAA=
    $ encargs base64:Z2l0AGNvbW1pdAAtbQBJbml0aWFsIGNvbW1pdAA=
    [master (root-commit) 76888a0] Initial commit
     1 file changed, 31 insertions(+)
     create mode 100644 README.md
```
```sh
    $ printf '%s\0' rsync -q -ax -e 'ssh -o BatchMode=yes' /srv/tree/ '[2001:db8:1d:8::903]:/srv/tree/' | base64 -w 0
    cnN5bmMALXEALWF4AC1lAHNzaCAtbyBCYXRjaE1vZGU9eWVzAC9zcnYvdHJlZS8AWzIwMDE6ZGI4OjFkOjg6OjkwM106L3Nydi90cmVlLwA=
    $ op=$(printf '%s\0' rsync -q -ax -e 'ssh -o BatchMode=yes' /srv/tree/ '[2001:db8:1d:8::903]:/srv/tree/' | base64 -w 0)
    $ ssh 2001:db8:1d:a::80a encargs base64:$op
    <...>
    ^Crsync error: received SIGINT, SIGTERM, or SIGHUP (code 20) at rsync.c(713) [sender=3.2.7]
```

## Building from source
This utility has no dependencies outside a C toolchain and
[muon(1)](https://muon.build/), which itself can be built with only a C
toolchain.
```sh
    $ muon setup -Dbuildtype=release out
    $ muon samu -C out
    $ muon -C out test
    $ DESTDIR=$buildroot muon -C out install
```
