/*
 * Copyright (c) 2014 Travis Geiselbrecht
 *
 * Use of this source code is governed by a MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */
#include <lk/asm.h>
#include <arch/arm/cores.h>

.text
.syntax unified
.thumb
.align 2

/* void bzero(void *s, size_t n); */
FUNCTION(bzero)
    mov     r2, r1
    movs    r1, #0

/* void *memset(void *s, int c, size_t n); */
FUNCTION(memset)
    // save the original pointer
    push    { r0, lr }

    // check for zero length
    cbz     r2, .L_done

    // short memsets aren't worth optimizing and make sure we have
    // enough headroom to try to do dwordwise move optimization
    cmp     r2, #16
    blt     .L_bytewise

    // see how many bytes we need to move to align to dword boundaries
    and     r3, r0, #7
    cbz     r3, .L_prepare_dwordwise
    rsb     r3, #8
    subs    r2, r3

.L_bytewise_align:
    // bytewise to align memset
    subs    r3, r3, #1
    strb    r1, [r0], #1
    bgt     .L_bytewise_align

.L_prepare_dwordwise:
    // fill a pair of 32 bit registers with the 8 bit value
    uxtb    r1, r1
    orr     r1, r1, r1, lsl #8
    orr     r1, r1, r1, lsl #16
    mov     r12, r1

    // load the number of dwords left
    lsrs    r3, r2, #3

.L_dwordwise:
    // dwordwise memset
    subs    r3, r3, #1
    strd    r1, r12, [r0], #8
    bgt     .L_dwordwise

    // remaining bytes
    ands     r2, #7
    beq     .L_done

.L_bytewise:
    // bytewise memset
    subs    r2, r2, #1
    strb    r1, [r0], #1
    bgt     .L_bytewise

.L_done:
    // restore the base pointer as return value
    pop     { r0, pc }

