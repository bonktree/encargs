#include <limits.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <assert.h>
#include <errno.h>
#include <error.h>
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "util.h"

/* Given a char @c from the base64 alphabet, returns the 6-bit value it
 * represents. If @c is not part of base64 alphabet, returns -EILSEQ.
 *
 * This function does not care about special processing of `='.
 */
static int unbase64_xfrm(char c) {
        unsigned offset;

        if (c >= 'A' && c <= 'Z')
                return c - 'A';

        offset = 'Z' - 'A' + 1;

        if (c >= 'a' && c <= 'z')
                return c - 'a' + offset;

        offset += 'z' - 'a' + 1;

        if (c >= '0' && c <= '9')
                return c - '0' + offset;

        offset += '9' - '0' + 1;

        if (c == '+')
                return offset;

        offset++;

        if (c == '/')
                return offset;

        return -EILSEQ;
}

/* Iterates over the memory slice defined by @*p and @*l.
 * Returns a negative exception code,
 *         or a non-negative decoded char <= 0xff,
 *         or INT_MAX for a padding byte.
 * Puts @*p and @*l at the decoded char.
 */
static int unbase64_next(const char **p, size_t *l) {
        int ret;

        /* Since we are not library code, we can afford to abort on invalid arguments. */
        assert(p);
        assert(l);

        /* Find the next non-whitespace character, and decode it. If we find padding,
         * we return it as INT_MAX. We greedily skip all preceding whitespace.
         */
        for (;;) {
                if (*l == 0)
                        return -EPIPE;

                if (!strchr(" \t\n\r", **p))
                        break;

                /* Skip leading whitespace. */
                (*p)++, (*l)--;
        }

        if (**p == '=')
                ret = INT_MAX; /* return padding as INT_MAX */
        else {
                ret = unbase64_xfrm(**p);
                if (ret < 0)
                        return ret;
        }
        return ret;
}

/* Advances @*p and @*l, greedily skipping all following whitespace. */
static void unbase64_advance(const char **p, size_t *l) {
        for (;;) {
                (*p)++, (*l)--;

                if (*l == 0)
                        break;
                if (!strchr(" \t\n\r", **p))
                        break;

                /* Skip the following whitespace. */
        }
}

/* Decodes a base64 string defined by the memory slice @p of length @l.
 * Returns 0 or a negative error code.
 * If the input sequence was correctly decoded, 0 is returned, a memory slice
 * pointing at decoded output is stored at @*out and @*out_size.
 * If the input sequence is not correct base64, @*out is set
 * to %NULL, and @*out_size is set to the offset of first error.
 *
 * The following error codes can be returned:
 *         -EINVAL	@p or @l are incorrect.
 *         -ENOMEM	Failed to allocate memory for @*out.
 *         -EILSEQ	Illegal bytes in input sequence.
 *          -EPIPE	Input sequence ends too early.
 *   -ENAMETOOLONG	Input sequence has extra octets after final padding.
 */
int unbase64_allocate(const char *p, size_t l, void **out, size_t *out_size) {
        _cleanup_free_ uint8_t *buf = NULL;
        const char *x;
        uint8_t *z;
        size_t len;
        bool padding = 0;

        assert_return(p || l == 0, -EINVAL);

        if (l == SIZE_MAX)
                l = strlen(p);

        /* A group of four input bytes needs three output bytes, in case of padding
         * we need to add two or three extra bytes. Note that this calculation
         * is an upper boundary, as we ignore whitespace while decoding.
         *
         * The practical input size will be limited by execve argv array length,
         * so we do not do unbounded allocations.
         */
        len = (l / 4) * 3 + (l % 4 == 0 ? 0 : (l % 4) - 1);

        buf = malloc(len + 1);
        if (!buf)
                return -ENOMEM;

        for (x = p, z = buf;;) {
                /* a == 0b00XXXXXX; b == 0b00YYYYYY; c == 0b00ZZZZZZ; d == 0b00UUUUUU; */
                int a, b, c, d;

                a = unbase64_next(&x, &l);
                if (a == -EPIPE)
                        /* Expected end of string. */
                        break;
                if (a < 0) {
                        *out = NULL;
                        *out_size = (size_t) (x - p - 0);
                        return a;
                }
                /* Padding is not allowed at the beginning of a 4-octet block. */
                if (a == INT_MAX) {
                        *out = NULL;
                        *out_size = (size_t) (x - p - 0);
                        return -EILSEQ;
                }
                unbase64_advance(&x, &l);

                b = unbase64_next(&x, &l);
                if (b < 0) {
                        *out = NULL;
                        *out_size = (size_t) (x - p - 0);
                        return b;
                }
                /* Padding is not allowed at the second character of a 4-octet block either. */
                if (b == INT_MAX) {
                        *out = NULL;
                        *out_size = (size_t) (x - p - 0);
                        return -EILSEQ;
                }
                unbase64_advance(&x, &l);

                c = unbase64_next(&x, &l);
                if (c < 0) {
                        *out = NULL;
                        *out_size = (size_t) (x - p - 0);
                        return c;
                }

                if (c == INT_MAX) { /* Padding at the third character */
                        padding = 1;
                        /* b == 0b00YY0000 */
                        if (b & 15) {
                                *out = NULL;
                                *out_size = (size_t) (x - p - 1);
                                return -EILSEQ;
                        }
                }
                unbase64_advance(&x, &l);

                d = unbase64_next(&x, &l);
                if (d < 0) {
                        *out = NULL;
                        *out_size = (size_t) (x - p - 0);
                        return d;
                }

                /* If the third character is padding, the fourth must be as well. */
                if (c == INT_MAX && d != INT_MAX) {
                        *out = NULL;
                        *out_size = (size_t) (x - p - 0);
                        return -EILSEQ;
                }

                if (c != INT_MAX && d == INT_MAX) {
                        padding = 1;
                        /* c == 0b00ZZZZ00 */
                        if (c & 3) {
                                *out = NULL;
                                *out_size = (size_t) (x - p - 1);
                                return -EILSEQ;
                        }
                }
                unbase64_advance(&x, &l);

                if (padding && l > 0) { /* Trailing rubbish? */
                        *out = NULL;
                        *out_size = (size_t) (x - p - 0);
                        return -ENAMETOOLONG;
                }

                *(z++) = (uint8_t) a << 2 | (uint8_t) b >> 4; /* XXXXXXYY */
                if (c == INT_MAX)
                        break;
                *(z++) = (uint8_t) b << 4 | (uint8_t) c >> 2; /* YYYYZZZZ */
                if (d == INT_MAX)
                        break;
                *(z++) = (uint8_t) c << 6 | (uint8_t) d;      /* ZZUUUUUU */
        }

        *z = 0;

        assert((size_t) (z - buf) <= len);

        if (out_size)
                *out_size = (size_t) (z - buf);
        if (out)
                *out = takep(&buf);

        return 0;
}
