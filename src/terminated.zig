const std = @import("std");
const parcom = @import("parcom.zig");
const Parser = parcom.Parser;
const Error = parcom.Error;
const Result = parcom.Result;
const get_return_type = parcom.get_return_type;

pub fn terminated(
    comptime t: anytype,
    comptime end: anytype,
) Parser(get_return_type(t)) {
    comptime {
        const ReturnType = get_return_type(t);
        const impl = struct {
            fn parse(input: []const u8) Error!Result(ReturnType) {
                if (input.len == 0) return Error.EndOfStream;

                var result = try t(input);
                var end_result = try end(result.input);
                result.input = end_result.input;

                return result;
            }
        };

        return impl.parse;
    }
}

////////////////////////////////////////
// Tests
////////////////////////////////////////

test "terminated" {
    const tag = parcom.parser.tag;
    const parser = terminated(tag("123"), tag("X"));

    const result = try parser("123X");
    try std.testing.expectEqualStrings("", result.input);
    try std.testing.expectEqualStrings("123", result.value);
}

test "terminated invalid terminee (end of stream)" {
    const tag = parcom.parser.tag;
    const parser = terminated(tag("123"), tag("X"));

    const result = parser("123");
    try std.testing.expectError(Error.EndOfStream, result);
}

test "terminated invalid terminee" {
    const tag = parcom.parser.tag;
    const parser = terminated(tag("123"), tag("X"));

    const result = parser("123Y");
    try std.testing.expectError(Error.InvalidToken, result);
}

test "terminated invalid parser" {
    const tag = parcom.parser.tag;
    const parser = terminated(tag("123"), tag("X"));

    const result = parser("12X");
    try std.testing.expectError(Error.InvalidToken, result);
}
