const std = @import("std");
const parcom = @import("parcom.zig");
const Parser = parcom.Parser;
const Error = parcom.Error;
const Result = parcom.Result;
const get_return_type = parcom.get_return_type;
const get_return_type_multiple = parcom.get_return_type_multiple;

pub fn seq(comptime t: anytype) Parser(get_return_type_multiple(t)) {
    comptime {
        const type_info = @typeInfo(@TypeOf(t));
        if (type_info != .Struct) @compileError("Expected tuple or struct");

        const n_fields = type_info.Struct.fields.len;
        const ReturnType = get_return_type(t);
        const impl = struct {
            fn parse(input: []const u8) Error!Result([n_fields]ReturnType) {
                if (input.len == 0) return Error.EndOfStream;

                var cursor = input;
                var results: [n_fields]ReturnType = undefined;
                inline for (t, 0..) |parser, i| {
                    const result = try parser(cursor);
                    cursor = result.input;
                    results[i] = result.value;
                }

                return .{
                    .input = cursor,
                    .value = results,
                };
            }
        };

        return impl.parse;
    }
}

////////////////////////////////////////
// SECTION: Tests
////////////////////////////////////////

test "seq valid" {
    const tag = parcom.parser.tag;

    const result = try seq(.{ tag("a"), tag("b") })("ab");
    try std.testing.expectEqualStrings("", result.input);

    try std.testing.expectEqualStrings("a", result.value[0]);
    try std.testing.expectEqualStrings("b", result.value[1]);
}

test "seq invalid" {
    const tag = parcom.parser.tag;

    const result = seq(.{ tag("a"), tag("b") })("ba");
    try std.testing.expectError(Error.InvalidToken, result);
}
