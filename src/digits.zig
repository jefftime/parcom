const std = @import("std");
const parcom = @import("parcom.zig");
const Result = parcom.Result;
const Error = parcom.Error;
const InputType = parcom.InputType;
const many = parcom.combinator.many;
const one_of = parcom.parser.one_of;

pub fn digits(input: InputType) Error!Result(u64) {
    try parcom.end_of_stream_check(input);

    const result = try many(one_of("0123456789"))(input);
    defer result.value.deinit();
    const number = std.fmt.parseInt(u32, result.value.items, 10) catch {
        return Error.InvalidParse;
    };
    return .{ .input = result.input, .value = number };
}

////////////////////////////////////////
// SECTION: Tests
////////////////////////////////////////

test "digits valid" {
    parcom.ALLOCATOR = std.testing.allocator;

    const result = try digits("1234");
    try std.testing.expectEqualStrings("", result.input);
    try std.testing.expectEqual(@as(u64, 1234), result.value);
}

test "digits valid 2" {
    parcom.ALLOCATOR = std.testing.allocator;

    const result = try digits("4321abc");
    try std.testing.expectEqualStrings("abc", result.input);
    try std.testing.expectEqual(@as(u64, 4321), result.value);
}

test "digits end of stream" {
    const result = digits("");
    try std.testing.expectError(Error.EndOfStream, result);
}

test "digits invalid" {
    parcom.ALLOCATOR = std.testing.allocator;

    const result = digits("-1234");
    try std.testing.expectError(Error.InvalidToken, result);
}
