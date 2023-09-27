const std = @import("std");
const parcom = @import("parcom.zig");
const Error = parcom.Error;
const Parser = parcom.Parser;
const Result = parcom.Result;
const get_return_type = parcom.get_return_type;

pub fn many1(comptime t: anytype) Parser(std.ArrayList(get_return_type(t))) {
    comptime {
        if (@typeInfo(@TypeOf(t)) != .Fn) {
            @compileError("Expected function");
        }

        const ReturnType = std.ArrayList(get_return_type(t));
        const impl = struct {
            fn parse(ipt: []const u8) Error!Result(ReturnType) {
                var input = ipt;

                const allocator = parcom.ALLOCATOR orelse {
                    return Error.AllocatorNotSet;
                };

                const first = try t(input);

                var results = ReturnType.init(allocator);
                input = first.input;
                results.append(first.value) catch return Error.AllocationError;
                errdefer results.deinit();

                while (t(input) catch null) |match| {
                    input = match.input;
                    results.append(match.value) catch {
                        return error.AllocationError;
                    };
                }

                return .{ .input = input, .value = results };
            }
        };

        return impl.parse;
    }
}

////////////////////////////////////////
// Tests
////////////////////////////////////////

// fn a_parser(input: []const u8) Error!Result(u8) {
//     if (input.len == 0) return error.EndOfStream;
//     if (input[0] == 'a') return .{ .input = input[1..], .value = input[0] };
//     return Error.InvalidToken;
// }

test "a_parser valid" {
    const tag = @import("parser.zig").tag;

    const input = "a";
    const result = try tag("a")(input);
    try std.testing.expectEqualStrings("", result.input);
    try std.testing.expectEqualStrings("a", result.value);
}

test "a_parser invalid character" {
    const tag = @import("parser.zig").tag;

    const input = "b";
    const result = tag("a")(input);
    try std.testing.expectError(Error.InvalidToken, result);
}

test "a_parser end of stream" {
    const tag = @import("parser.zig").tag;

    const input = "";
    const result = tag("a")(input);
    try std.testing.expectError(Error.EndOfStream, result);
}

test "many1 single character" {
    const tag = @import("parser.zig").tag;
    parcom.ALLOCATOR = std.testing.allocator;

    const input = "a";
    const parser = many1(tag("a"));
    const result = try parser(input);
    const expecteds = &[_][]const u8{"a"};
    for (expecteds, result.value.items) |expected, actual| {
        try std.testing.expectEqualStrings(expected, actual);
    }

    result.value.deinit();
}

test "many1 multiple characters" {
    const tag = @import("parser.zig").tag;
    parcom.ALLOCATOR = std.testing.allocator;

    const input = "aaa";
    const parser = many1(tag("a"));
    const result = try parser(input);
    try std.testing.expectEqualStrings("", result.input);
    const expecteds = &[_][]const u8{ "a", "a", "a" };
    for (expecteds, result.value.items) |expected, actual| {
        try std.testing.expectEqualStrings(expected, actual);
    }

    result.value.deinit();
}

test "many1 multiple characters with leftovers" {
    const tag = @import("parser.zig").tag;
    parcom.ALLOCATOR = std.testing.allocator;

    const input = "aaabcd";
    const parser = many1(tag("a"));
    const result = try parser(input);
    try std.testing.expectEqualStrings("bcd", result.input);
    const expecteds = &[_][]const u8{ "a", "a", "a" };
    for (expecteds, result.value.items) |expected, actual| {
        try std.testing.expectEqualStrings(expected, actual);
    }

    result.value.deinit();
}

test "many1 single character with leftovers" {
    const tag = @import("parser.zig").tag;
    parcom.ALLOCATOR = std.testing.allocator;

    const input = "abcd";
    const parser = many1(tag("a"));
    const result = try parser(input);
    try std.testing.expectEqualStrings("bcd", result.input);
    const expecteds = &[_][]const u8{"a"};
    for (expecteds, result.value.items) |expected, actual| {
        try std.testing.expectEqualStrings(expected, actual);
    }

    result.value.deinit();
}

test "many1 invalid allocator" {
    const tag = @import("parser.zig").tag;
    // WARN: Possible bug report? Feels like we shouldn't have to set this
    parcom.ALLOCATOR = null;

    const input = "a";
    const parser = many1(tag("a"));
    const result = (parser(input));
    try std.testing.expectError(Error.AllocatorNotSet, result);
}

test "many1 failing allocator" {
    const tag = @import("parser.zig").tag;
    parcom.ALLOCATOR = std.testing.failing_allocator;

    const input = "a";
    const parser = many1(tag("a"));
    const result = parser(input);
    try std.testing.expectError(Error.AllocationError, result);
}
