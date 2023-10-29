const std = @import("std");
const parcom = @import("parcom.zig");
const Result = parcom.Result;
const Error = parcom.Error;
const InputType = parcom.InputType;
const maybe = parcom.combinator.maybe;
const tag = parcom.parser.tag;
const digits = parcom.parser.digits;

pub fn number(input: InputType) Error!Result(i32) {
    try parcom.end_of_stream_check(input);

    const minus_result = try maybe(tag("-"))(input);

    const negative = if (minus_result.value != null) true else false;
    const result = try digits(minus_result.input);

    var n: i32 = @intCast(result.value);
    if (negative) n = -n;

    return .{ .input = result.input, .value = n };
}

////////////////////////////////////////
// SECTION: Tests
////////////////////////////////////////

test "positive number" {
    const result = try number("1234");
    try std.testing.expectEqualStrings("", result.input);
    try std.testing.expectEqual(@as(i32, 1234), result.value);
}

test "negative number" {
    const result = try number("-1234");
    try std.testing.expectEqualStrings("", result.input);
    try std.testing.expectEqual(@as(i32, -1234), result.value);
}

test "invalid number" {
    const result = number("abc");
    try std.testing.expectError(Error.InvalidToken, result);
}

test "number end of stream" {
    const result = number("");
    try std.testing.expectError(Error.EndOfStream, result);
}

test "invalid number with minus sign" {
    const result = number("-abc");
    try std.testing.expectError(Error.InvalidToken, result);
}
