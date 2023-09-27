const std = @import("std");
const parcom = @import("parcom.zig");
const Parser = parcom.Parser;
const Error = parcom.Error;
const Result = parcom.Result;
const get_return_type = parcom.get_return_type;

pub fn seq(comptime t: anytype) Parser(get_return_type(t)) {
    comptime {
        if (@typeInfo(@TypeOf(t)) != .Struct) {
            @compileError("Expected tuple or struct");
        }

        const ReturnType = get_return_type(t);
        const impl = struct {
            fn parse(input: []const u8) Error!Result(ReturnType) {
                _ = input;
                unreachable;
            }
        };

        return impl.parse;
    }
}
