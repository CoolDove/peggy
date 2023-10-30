package main

import "core:c"
import "core:c/libc"
import "core:os"
import "core:mem"
import "core:fmt"
import "core:strings"
import "pac/fe"


FE_BUFFER_SIZE :: 1024 * 1024 * 1024

fe_ctx : ^fe.Context

main :: proc() {
    fe_mem, alloc_err := mem.alloc_bytes(FE_BUFFER_SIZE); defer mem.free(raw_data(fe_mem))
    fe_ctx = fe.open(raw_data(fe_mem), FE_BUFFER_SIZE); defer fe.close(fe_ctx)

    install_functions()

    gc := fe.savegc(fe_ctx)

    reader : SourceReader
    reader.src = "(+ 12 (print (hello 24)))"
    for {
        obj :^fe.Object= fe.read(fe_ctx, auto_cast fe_read_source, &reader)
        if obj == nil do break
        /* evaluate read object */
        fe.eval(fe_ctx, obj)

        /* restore GC stack which would now contain both the read object and
        ** result from evaluation */
        fe.restoregc(fe_ctx, gc);
    }
}

install_functions :: proc() {
    fe.set(fe_ctx, fe.symbol(fe_ctx, "addtwo"), fe.cfunc(fe_ctx, auto_cast cfunc_add2))
    fe.set(fe_ctx, fe.symbol(fe_ctx, "hello"), fe.cfunc(fe_ctx, auto_cast cfunc_hello))
}

cfunc_add2 :: proc(ctx:^fe.Context, args: ^fe.Object) -> ^fe.Object {
    argsptr := args
    a := fe.tonumber(ctx, fe.nextarg(ctx, &argsptr))
    return fe.number(fe_ctx, a+2)
}
cfunc_hello :: proc(ctx:^fe.Context, args: ^fe.Object) -> ^fe.Object {
    argsptr := args
    buffer : [1024]u8
    length := fe.tostring(ctx, fe.nextarg(ctx, &argsptr), raw_data(buffer[:]), 1024)
    fmt.printf("len: {}\n", length)
    name := (string)(buffer[:length])
    fmt.printf("Hello: {}\n", name)
    return fe.number(fe_ctx, 1)
}

SourceReader :: struct {
    ptr: int,
    src: string,
}

fe_read_source :: proc(ctx:^fe.Context, udata:rawptr) -> u8 {
    source := cast(^SourceReader)udata
    using source
    if ptr >= len(src) do return 0
    b := src[ptr]
    ptr += 1
    return b
}