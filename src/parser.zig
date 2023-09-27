const std = @import("std");
const parcom = @import("parcom.zig");
const Error = parcom.Error;
const Parser = parcom.Parser;
const Result = parcom.Result;

pub fn tag(comptime str: []const u8) Parser([]const u8) {
    const impl = struct {
        fn parse(input: []const u8) Error!Result([]const u8) {
            try parcom.end_of_stream_check(input);

            if (input.len < str.len) return Error.InvalidToken;
            if (!std.mem.eql(u8, input[0..str.len], str)) {
                return Error.InvalidToken;
            }

            return .{
                .input = input[str.len..],
                .value = input[0..str.len],
            };
        }
    };

    return impl.parse;
}

////////////////////////////////////////
// Tests
////////////////////////////////////////

test "tag single character valid" {
    const input = "a";
    const p = tag("a");
    const result = try p(input);

    try std.testing.expectEqualStrings("", result.input);
    try std.testing.expectEqualStrings("a", result.value);
}

test "tag single character valid with leftovers" {
    const input = "abc";
    const p = tag("a");
    const result = try p(input);

    try std.testing.expectEqualStrings("bc", result.input);
    try std.testing.expectEqualStrings("a", result.value);
}

test "tag single character end of stream" {
    const input = "";
    const p = tag("a");
    const result = p(input);
    try std.testing.expectError(Error.EndOfStream, result);
}

test "tag single character invalid" {
    const input = "b";
    const p = tag("a");
    const result = p(input);

    try std.testing.expectError(Error.InvalidToken, result);
}

test "tag multi character valid" {
    const input = "abc";
    const p = tag("abc");
    const result = try p(input);

    try std.testing.expectEqualStrings("", result.input);
    try std.testing.expectEqualStrings("abc", result.value);
}

test "tag multi character valid with leftovers" {
    const input = "abc123";
    const p = tag("abc");
    const result = try p(input);

    try std.testing.expectEqualStrings("123", result.input);
    try std.testing.expectEqualStrings("abc", result.value);
}

test "tag multi character invalid" {
    const input = "ab3";
    const p = tag("abc");
    const result = p(input);

    try std.testing.expectError(Error.InvalidToken, result);
}
