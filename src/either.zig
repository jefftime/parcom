const std = @import("std");
const parcom = @import("parcom.zig");
const Parser = parcom.Parser;
const get_return_type = parcom.get_return_type;
const Error = parcom.Error;
const Result = parcom.Result;

pub fn either(comptime t: anytype) Parser(get_return_type(t)) {
    comptime {
        if (@typeInfo(@TypeOf(t)) != .Struct) {
            @compileError("Expected tuple or struct");
        }

        const ReturnType = get_return_type(t);
        const impl = struct {
            fn parse(input: []const u8) Error!Result(ReturnType) {
                if (input.len == 0) return Error.EndOfStream;

                inline for (t) |parser| {
                    var result = parser(input) catch null;
                    if (result) |r| return r;
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

const DigitParser = struct {
    fn parse(input: []const u8) Error!Result(u8) {
        if (input.len == 0) return Error.EndOfStream;

        if (std.ascii.isDigit(input[0])) {
            const number = std.fmt.parseInt(u8, input[0..1], 10) catch {
                return Error.InvalidToken;
            };
            return .{ .input = input[1..], .value = number };
        }

        return Error.InvalidToken;
    }
};

const LetterParser = struct {
    fn parse(input: []const u8) Error!Result(u8) {
        if (input.len == 0) return Error.EndOfStream;

        if (std.ascii.isAlphabetic(input[0])) {
            return .{ .input = input[1..], .value = input[0] };
        }

        return Error.InvalidToken;
    }
};

const HyphenParser = struct {
    fn parse(input: []const u8) Error!Result(u8) {
        if (input.len == 0) return Error.EndOfStream;

        if (input[0] == '-') {
            return .{ .input = input[1..], .value = input[0] };
        }

        return Error.InvalidToken;
    }
};

test "either - two parsers - DigitParser" {
    const new_parser = either(.{ DigitParser.parse, LetterParser.parse });

    const input = "1";
    const result = (try new_parser(input));
    try std.testing.expectEqualSlices(u8, "", result.input);
    try std.testing.expectEqual(@as(u8, 1), result.value);
}

test "either - two parsers - LetterParser" {
    const new_parser = either(.{ DigitParser.parse, LetterParser.parse });
    const input = "a";
    const result = (try new_parser(input));
    try std.testing.expectEqualSlices(u8, "", result.input);
    try std.testing.expectEqual(@as(u8, 'a'), result.value);
}

test "either - two parsers - no match" {
    const new_parser = either(.{ DigitParser.parse, LetterParser.parse });
    const input = "-";
    const err_result = new_parser(input);
    try std.testing.expectError(Error.InvalidToken, err_result);
}

test "either - two parsers - empty input" {
    const new_parser = either(.{ DigitParser.parse, LetterParser.parse });
    const input = "";
    const err_result = new_parser(input);
    try std.testing.expectError(Error.EndOfStream, err_result);
}

test "either - three parsers - placement test beginning" {
    const new_parser = either(.{
        HyphenParser.parse,
        DigitParser.parse,
        LetterParser.parse,
    });
    const input = "-";
    const result = try new_parser(input);
    try std.testing.expectEqualSlices(u8, "", result.input);
    try std.testing.expectEqual(@as(u8, '-'), result.value);
}

test "either - three parsers - placement test middle" {
    const new_parser = either(.{
        DigitParser.parse,
        HyphenParser.parse,
        LetterParser.parse,
    });
    const input = "-";
    const result = try new_parser(input);
    try std.testing.expectEqualSlices(u8, "", result.input);
    try std.testing.expectEqual(@as(u8, '-'), result.value);
}

test "either - three parsers - placement test end" {
    const new_parser = either(.{
        DigitParser.parse,
        LetterParser.parse,
        HyphenParser.parse,
    });
    const input = "-";
    const result = try new_parser(input);
    try std.testing.expectEqualSlices(u8, "", result.input);
    try std.testing.expectEqual(@as(u8, '-'), result.value);
}

test "either - complex" {
    const tag = parcom.parser.tag;

    const new_parser = either(.{
        tag("abc"),
        tag("123"),
    });

    var input = "abc000";
    var result = try new_parser(input);
    try std.testing.expectEqualStrings("000", result.input);
    try std.testing.expectEqualStrings("abc", result.value);

    input = "123aaa";
    result = try new_parser(input);
    try std.testing.expectEqualStrings("aaa", result.input);
    try std.testing.expectEqualStrings("123", result.value);
}

// test "either - deeply nested" {
//     const many1 = parcom.many1;
//     const tag = parcom.parser.tag;

//     const new_parser = either(.{
//         many1(tag("a")),
//         many1(tag("bc")),
//     });

//     var input: []const u8 = "aaa123";
//     var result = try new_parser(input);
//     try std.testing.expectEqualStrings("123", result.input);
//     var expecteds = &[_][]const u8{ "a", "a", "a" };
//     for (expecteds, result.value.items) |expected, actual| {
//         try std.testing.expectEqualStrings(expected, actual);
//     }
//     result.value.deinit();

//     // input = "bc123";
//     // result = try new_parser(input);
//     // try std.testing.expectEqualStrings("123", result.input);
//     // try std.testing.expectEqualStrings("bc", result.value);
// }
