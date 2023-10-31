package main

import "core:strings"
import "core:mem"
import "pac/fe"


@(private="file")
_to_string_buffer : [2048]u8

fe_tostring :: proc(ctx:^fe.Context, obj:^fe.Object, allocator:=context.allocator) -> string {
    context.allocator = allocator
    length := fe.tostring(fe_ctx, obj, raw_data(_to_string_buffer[:]), 2048)
    return strings.clone_from(_to_string_buffer[:length])
}