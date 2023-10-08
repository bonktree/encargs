// SPDX-License-Identifier: GPL-2.0
#include <inttypes.h>
#include <limits.h>
#include <stdbool.h>
#include <stddef.h>
#include <errno.h>
#include <error.h>
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "util.h"
#include <encargs-config.h>

int unbase64_allocate(const char *p, size_t l, void **ret, size_t *ret_size);

int decode_allocate(const char* arg, void** out_buf, size_t* out_len) {
        /* A decoder might leave those unset. */
        *out_buf = NULL;
        *out_len = 0;

        char* source;
        source = strprefix(arg, "base64:");
        if (source)
                return unbase64_allocate(source, strlen(source), out_buf, out_len);

        return -EOPNOTSUPP;
}

static struct option cmdlineopts[] = {
        /* -h, --help
         *
         * Causes the program to write help text to standard output
         * and immediately successfully terminate.
         */
        {"help", no_argument, NULL, 'h'},
        /* -V, --version
         *
         * Causes the program to write its version to standard output
         * and immediately successfully terminate.
         */
        {"version", no_argument, NULL, 'V'},
        /* End of list. */
        {0},
};

static void print_version_n_die(int exit_code) {
        fprintf(stdout, "%s version %s\n", PROJECT_NAME, PROJECT_VERSION);
        exit(exit_code);
}

void show_help_n_die(int exitcode) {
        FILE* fp = exitcode != EXIT_SUCCESS ? stderr : stdout;
        fprintf(fp, "Usage: %s [options] [encoding]:[command]\n"
                    "\n"
                    "  --help, -h            show this help text\n"
                    "  --version, -V         show program version\n"
                    "\n"
                    "The only supported encoding is base64.\n"
                    "The command is encoded in a way to not be mangled\n"
                    "by a shell unquote pass.\n"
                    , program_invocation_short_name);
        exit(exitcode);
}

ssize_t argz_elements(const char** destv, const char* argz, size_t alen) {
        const char** p = destv;
        size_t ret = 0, l;

        if (alen > SSIZE_MAX)
                alen = SSIZE_MAX;

        for (; alen;) {
                l = strnlen(argz, alen - 1);
                if (destv)
                        *p++ = argz;
                argz += l;
                alen -= l;
                if (*argz)
                        /* This command word is not '\0'-terminated. */
                        return -EINVAL;
                argz += 1;
                alen -= 1;
                ret += 1;
        }
        return ret;
}

int main(int argc, char* argv[]) {
        int ret;
        int pos_argc;
        char** pos_argv;

        if (argc < 2)
                return 1;

        int __optoffset = 0;
        while (1) {
                ret = getopt_long(argc, argv, "hV", cmdlineopts, &__optoffset);
                if (ret == -1)
                        break;
                switch (ret) {
                case 'h':
                        show_help_n_die(EXIT_SUCCESS);
                        break;
                case 'V':
                        print_version_n_die(EXIT_SUCCESS);
                        break;
                case '?':
                        show_help_n_die(EXIT_FAILURE);
                }
        }
        if (argc > optind) {
                pos_argc = argc - optind;
                pos_argv = &argv[optind];
        }
        else {
                pos_argc = 0;
                pos_argv = NULL;
        }

        /* Positional arguments are expected to contain an encoded argv. */
        /* For now, expect a single argument. */
        if (pos_argc < 1) {
                error(EXIT_FAILURE, 0, "Missing operand.");
        }

        _cleanup_free_ void* decargz;
        size_t decargz_len;
        ret = decode_allocate(pos_argv[0], &decargz, &decargz_len);
        if (ret == -EOPNOTSUPP)
                error(EXIT_FAILURE, 0, "Missing or unknown operand encoding.");
        if (ret == -EPIPE)
                error(EXIT_FAILURE, 0, "Unexpected end-of-string at input byte %" PRIu64 ".", decargz_len);
        if (ret == -EILSEQ)
                error(EXIT_FAILURE, 0, "Invalid input byte %" PRIu64 ".", decargz_len);
        if (ret == -ENAMETOOLONG)
                error(EXIT_FAILURE, 0, "Trailing rubbish at input byte %" PRIu64 ".", decargz_len);
        if (ret < 0)
                error(EXIT_FAILURE, -ret, "Decoding error");

        _cleanup_free_ char** decargv;
        ssize_t decargv_len;
        decargv_len = argz_elements(NULL, decargz, decargz_len);
        if (decargv_len < 0)
                error(EXIT_FAILURE, 0, "Truncated command line.");
        if (decargv_len == 0)
                error(EXIT_FAILURE, 0, "Empty command line.");
        decargv = calloc(sizeof(decargv[0]), decargv_len + 1);
        if (!decargv)
                error(EXIT_FAILURE, ENOMEM, "ENOMEM");

        const char** v = (const char**)decargv;
        argz_elements(v, decargz, decargz_len);
        v += decargv_len;
        *v++ = NULL;

        execvp(decargv[0], decargv);
        error(EXIT_FAILURE, errno, "exec");
}
