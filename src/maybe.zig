const std = @import("std");
const parcom = @import("parcom.zig");
const Parser = parcom.Parser;
const Error = parcom.Error;
const Result = parcom.Result;
const get_return_type = parcom.get_return_type;

pub fn maybe(comptime t: anytype) Parser(?get_return_type(t)) {
    comptime {
        const impl = struct {
            const ReturnType = get_return_type(t);
            fn parse(input: []const u8) Error!Result(?ReturnType) {
                const result = t(input) catch null;

                if (result) |r| return .{ .input = r.input, .value = r.value };

                return .{ .input = input, .value = null };
            }
        };

        return impl.parse;
    }
}

////////////////////////////////////////
// Tests
////////////////////////////////////////

test "maybe valid" {
    const tag = parcom.parser.tag;
    const parser = maybe(tag("123"));

    const result = try parser("123");
    try std.testing.expectEqualStrings("", result.input);
    try std.testing.expectEqualStrings("123", result.value.?);
}

test "maybe invalid" {
    const tag = parcom.parser.tag;
    const parser = maybe(tag("123"));

    const result = try parser("456");
    try std.testing.expectEqualStrings("456", result.input);
    try std.testing.expectEqual(@as(?[]const u8, null), result.value);
}

test "maybe with many valid" {
    const tag = parcom.parser.tag;
    const many = parcom.combinator.many;

    const parser = maybe(many(tag("a")));
    const result = try parser("aaa");
    const tags = result.value orelse @panic("Maybe with many failed");
    defer tags.deinit();

    try std.testing.expectEqualStrings("", result.input);
    const expecteds = &[_][]const u8{ "a", "a", "a" };
    for (expecteds, tags.items) |expected, actual| {
        try std.testing.expectEqualStrings(expected, actual);
    }
}

test "maybe with many invalid" {
    const tag = parcom.parser.tag;
    const many = parcom.combinator.many;

    const parser = maybe(many(tag("a")));
    const result = try parser("bbb");
    try std.testing.expectEqualStrings("bbb", result.input);
    try std.testing.expectEqual(
        @as(?std.ArrayList([]const u8), null),
        result.value,
    );
}
