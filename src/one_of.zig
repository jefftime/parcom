const std = @import("std");
const parcom = @import("parcom.zig");
const Parser = parcom.Parser;
const Error = parcom.Error;
const Result = parcom.Result;
const get_return_type = parcom.get_return_type;

pub fn one_of(comptime chars: []const u8) Parser(u8) {
    comptime {
        const impl = struct {
            fn parse(input: []const u8) Error!Result(u8) {
                if (input.len == 0) return Error.EndOfStream;

                for (chars) |c| {
                    if (input[0] == c) return .{
                        .input = input[1..],
                        .value = c,
                    };
                }

                return Error.InvalidToken;
            }
        };

        return impl.parse;
    }
}

////////////////////////////////////////
// Tests
////////////////////////////////////////

test "one_of valid" {
    const parser = one_of("abc");

    const result = try parser("b");
    try std.testing.expectEqualStrings("", result.input);
    try std.testing.expectEqual(@as(u8, 'b'), result.value);
}

test "one_of invalid" {
    const parser = one_of("abc");

    const result = parser("1");
    try std.testing.expectError(Error.InvalidToken, result);
}

test "one_of with many valid" {
    parcom.ALLOCATOR = std.testing.allocator;

    const many = parcom.combinator.many;
    const parser = many(one_of("abc"));

    const result = try parser("cba123");
    defer result.value.deinit();
    try std.testing.expectEqualStrings("123", result.input);
    try std.testing.expectEqualSlices(u8, "cba", result.value.items);
}

test "one_of with many invalid" {
    parcom.ALLOCATOR = std.testing.allocator;

    const many = parcom.combinator.many;
    const parser = many(one_of("abc"));

    const result = parser("123");
    try std.testing.expectError(Error.InvalidToken, result);
}
