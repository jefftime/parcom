const std = @import("std");
const parcom = @import("parcom.zig");
const Parser = parcom.Parser;
const Result = parcom.Result;
const Error = parcom.Error;
const InputType = parcom.InputType;
const get_return_type = parcom.get_return_type;
const end_of_stream_check = parcom.end_of_stream_check;
const whitespace_ignore = parcom.parser.whitespace_ignore;

pub fn trim(comptime t: anytype) Parser(InputType) {
    comptime {
        const ReturnType = get_return_type(t);
        const impl = struct {
            fn parse(input: InputType) Error!Result(ReturnType) {
                try end_of_stream_check(input);

                var ws_info = try whitespace_ignore(input);
                const result = try t(ws_info.input);
                ws_info = try whitespace_ignore(result.input);

                return .{ .input = ws_info.input, .value = result.value };
            }
        };

        return impl.parse;
    }
}

////////////////////////////////////////
// SECTION: Tests
////////////////////////////////////////

test "trim spaces both sides" {
    const tag = parcom.parser.tag;

    const parser = trim(tag("asdf"));
    const result = try parser("   asdf    123");
    try std.testing.expectEqualStrings("123", result.input);
    try std.testing.expectEqualStrings("asdf", result.value);
}

test "trim end" {
    const tag = parcom.parser.tag;

    const parser = trim(tag("asdf"));
    const result = try parser("asdf   123");
    try std.testing.expectEqualStrings("123", result.input);
    try std.testing.expectEqualStrings("asdf", result.value);
}

test "trim start" {
    const tag = parcom.parser.tag;

    const parser = trim(tag("asdf"));
    const result = try parser("   asdf123");
    try std.testing.expectEqualStrings("123", result.input);
    try std.testing.expectEqualStrings("asdf", result.value);
}

test "trim no whitespace" {
    const tag = parcom.parser.tag;

    const parser = trim(tag("asdf"));
    const result = try parser("asdf123");
    try std.testing.expectEqualStrings("123", result.input);
    try std.testing.expectEqualStrings("asdf", result.value);
}

test "trim newlines" {
    const tag = parcom.parser.tag;

    const input =
        \\
        \\asdf
        \\
        \\ 123
    ;
    const parser = trim(tag("asdf"));
    const result = try parser(input);
    try std.testing.expectEqualStrings("123", result.input);
    try std.testing.expectEqualStrings("asdf", result.value);
}
