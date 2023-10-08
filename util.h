#ifndef __E_common_util_h
#define __E_common_util_h

#include <stddef.h>
#include <string.h>
#include <stdarg.h>

#define nerr(no) #no

#define assert_return(pred, err) if (!(pred)) return (err)

#define ARRAY_SIZE(a) (sizeof(a) / sizeof(a[0]))

#define container_of(x, type, member) \
    ((type*)((char*)(x) - offsetof(type, member)))

void do_nothing();

/* Copy a pointer lvalue, NULL it out and return the copy. */
static inline void* takep(void* ptr) {
    assert_return(ptr, NULL);
    void* volatile *p = (void**)ptr;
    void* ret = *p;
    *p = NULL;
    return ret;
}
int closep(int*);
void freep(void*);
/* Same as freep(), but also forget garbage address. */
void dropp(void*);
/* Zero-fill all bytes of a nul-terminated string. */
void bzero_overwrite_cstrp(void*);

#define _cleanup_(f) __attribute__(( cleanup( f ) ))
#define _cleanup_free_ _cleanup_(freep)
#define _cleanup_close_ _cleanup_(closep)

char* strprefix(const char* source, const char* prefix);

#endif
