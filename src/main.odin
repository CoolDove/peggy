package main

import "core:c"
import "core:c/libc"
import "core:os"
import "core:mem"
import "pac/fe"


FE_BUFFER_SIZE :: 1024 * 1024 * 1024

fe_ctx : ^fe.Context

main :: proc() {
    fe_mem, alloc_err := mem.alloc_bytes(FE_BUFFER_SIZE); defer mem.free(raw_data(fe_mem))
    fe_ctx = fe.open(raw_data(fe_mem), FE_BUFFER_SIZE); defer fe.close(fe_ctx)

    gc := fe.savegc(fe_ctx)

    reader : SourceReader
    reader.src = "(print (+ 12 1))"
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