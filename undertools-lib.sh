# This is sourced by ./configure.

fatal() {
	printf >&2 "$0: %s\n" "$*"
        exit 1
}

cliopt_v=
conf_cli_options() {
# This can be either robust or simple.
for carg; do case $carg in
--help) ;;
--verbose) cliopt_v=1 ;;
--prefix=*)
	carg="${carg#--prefix=}"
        prefix="$carg"
        ;;
--*dir=*)
	carg="${carg#--}"
        eval "$carg"
	;;
--*) fatal "unexpected option: $carg" ;;
*) fatal "unexpected non-option: $carg" ;;
esac; done
}

produce() {

mkdir -p -- "$outdir"
cat > "$outdir/all/@msg" <<EOF
#!/bin/sh -eu

rc="\$1"; shift
printf '%s\n' "\$*"
exit \$rc
EOF
chmod +x -- "$outdir/all/@msg"

}

generate_file() {
	__target="$outdir/$1"; shift
	__format="$1"; shift
	printf >"$__target" "$__format" "$@"
}

# Usage: produce_rule name description
#
# Description can contain references to $target and $source.
produce_rule() {
	produce_rule_internal '' "$@"
}
produce_rule_trace() {
	produce_rule_internal 1 "$@"
}
produce_rule_internal() {

__trace="$1"; shift
[ -z "$cliopt_v" ] || cliopt_v="\$*"
mkdir -p -- "$outdir/all"
cat > "$outdir/all/@rule$1" <<EOF
#!/bin/sh -euf
# This file is (re-)generated.
#
# Execute a recipe to produce a target.
# Store the recipe in a companion file next to the target,
# to be consulted by tracing and code assist tools.
#
# Usage: out/all/@rule$1 target source "\$@"

cd "$outdir"
target="\$1"; shift
source="\$1"; shift
descr="${2-  $1 \$target}"
line="${cliopt_v:-\$descr}"

printf '%s\n' "\$line"

[ -z "$__trace" ] || {
printf '%s\0' source 1 "\$source"
printf '%s\0' directory 1 "$outdir"
# This one comes last, since this argz has variable length.
printf '%s\0' command "\$#" "\$@"
} > \$target.cmd

exec "\$@" 
EOF
chmod +x -- "$outdir/all/@rule$1"

}

produce_buildgraph() {

cat > "$outdir/Makefile" <<EOF
srcdir = $srcdir
outdir = $outdir

CC := $CC
CFLAGS := $CFLAGS
CPPFLAGS := $CPPFLAGS

EOF
cat "$srcdir"/Makefile.in >> "$outdir/Makefile"

}

produce_test() {

mkdir -p -- "$outdir/test"
cat > "$outdir/test/@" <<EOF
#!/bin/sh -euf
# This file is (re-)generated.
#
# Run tests on just-built artifacts.

set -euf

srcdir="$srcdir"
outdir="$outdir"

cd "$outdir"
printf 'Running test suite: %s\n' \$srcdir/tests/1-base64.sh
\$srcdir/tests/1-base64.sh
printf 'Running test suite: %s\n' \$srcdir/tests/2-exec-argz.sh
\$srcdir/tests/2-exec-argz.sh
printf 'Running test suite: %s\n' \$srcdir/tests/3-base64-whitespace.sh
\$srcdir/tests/3-base64-whitespace.sh

EOF
chmod +x -- "$outdir/test/@"

}

produce_install() {

mkdir -p -- "$outdir/install"
cat > "$outdir/install/@" <<EOF
#!/bin/sh -euf
# This file is (re-)generated.
#
# Install artifacts to specified prefix, possibly in a buildroot.

set -euf

outdir="$outdir"

DESTDIR="\${DESTDIR-}"; [ -z "\${DESTDIR}" ] || export DESTDIR
prefix="\${DESTDIR}$prefix"
bindir="\${prefix}/bin"

INSTALL="install -p"
INSTALL_DATA="\$INSTALL -m 644"
INSTALL_PROGRAM="\$INSTALL"
MKDIR_P="mkdir -p"

\${MKDIR_P} -v \${bindir}
\${INSTALL_PROGRAM} -v \${outdir}/encargs \${bindir}/encargs

EOF
chmod +x -- "$outdir/install/@"

mkdir -p -- "$outdir/check"
cat > "$outdir/check/@" <<'EOF'
#!/bin/sh -euf

tgt1="\`check'"
tgt2="\`test'"
printf >&2 '\t%s\n' "$tgt1"': This target, as opposed to '"$tgt2"','
printf >&2 '\t%s\n' 'was intended to test the installed artifacts;'
printf >&2 '\t%s\n' 'it is unimplemented.'
exit 1
EOF
chmod +x -- "$outdir/check/@"

}
