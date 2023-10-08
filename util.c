#include <assert.h>
#include <errno.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "util.h"

void do_nothing() {}

int closep(int* ptr) {
        assert_return(ptr, 0);
        return close(*ptr);
}

void freep(void* ptr) {
        if (!ptr) return;
        free(*(void**)ptr);
}

void dropp(void* ptr) {
        if (!ptr) return;
        void** p = (void**)ptr;
        free(*p);
        *p = NULL;
}

void bzero_overwrite_cstrp(void* ptr) {
        if (!ptr) return;
        volatile char *__it;
        volatile void** p = (volatile void**)ptr;
        if ((__it = (*p)))
                while (*__it)
                        *__it++ = '\0';
}

void perror_n_die(const char *s, int ret) {
        errno = (ret < 0) ? -ret : ret;
        perror(s);
        exit(ret);
}

void print_n_die(const char *s) {
        fprintf(stderr, "%s\n", s);
        exit(EXIT_FAILURE);
}

char* strprefix(const char* source, const char* prefix) {
        assert(source);
        assert(prefix);

        size_t pl = strlen(prefix);
        return strncmp(source, prefix, pl) ? NULL : (char*)source + pl;
}
