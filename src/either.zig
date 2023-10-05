const std = @import("std");
const parcom = @import("parcom.zig");
const Parser = parcom.Parser;
const get_return_type = parcom.get_return_type;
const Error = parcom.Error;
const Result = parcom.Result;
const InputType = parcom.InputType;

pub fn either(comptime t: anytype) Parser(get_return_type(t)) {
    comptime {
        if (@typeInfo(@TypeOf(t)) != .Struct) {
            @compileError("Expected tuple or struct");
        }

        const ReturnType = get_return_type(t);
        const impl = struct {
            fn parse(input: InputType) Error!Result(ReturnType) {
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
    fn parse(input: InputType) Error!Result(u8) {
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
    fn parse(input: InputType) Error!Result(u8) {
        if (input.len == 0) return Error.EndOfStream;

        if (std.ascii.isAlphabetic(input[0])) {
            return .{ .input = input[1..], .value = input[0] };
        }

        return Error.InvalidToken;
    }
};

const HyphenParser = struct {
    fn parse(input: InputType) Error!Result(u8) {
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

test "either - deeply nested" {
    const many = parcom.combinator.many;
    const tag = parcom.parser.tag;
    parcom.ALLOCATOR = std.testing.allocator;

    const new_parser = either(.{
        many(tag("a")),
        many(tag("bc")),
    });

    var result = try new_parser("aaa123");
    try std.testing.expectEqualStrings("123", result.input);
    const expecteds1 = &[_][]const u8{ "a", "a", "a" };
    for (expecteds1, result.value.items) |expected, actual| {
        try std.testing.expectEqualStrings(expected, actual);
    }
    result.value.deinit();

    result = try new_parser("bcbc123");
    try std.testing.expectEqualStrings("123", result.input);
    const expecteds2 = &[_]InputType{ "bc", "bc" };
    for (expecteds2, result.value.items) |expected, actual| {
        try std.testing.expectEqualStrings(expected, actual);
    }
    result.value.deinit();
}

test "either - bad allocator" {
    const many = parcom.combinator.many;
    const tag = parcom.parser.tag;

    parcom.ALLOCATOR = std.testing.failing_allocator;

    const new_parser = either(.{many(tag("a"))});

    const input = "a123";
    const result = new_parser(input);

    // WARN: This needs to be reworked. We probably need to propagate the
    // AllocatorNotSet errors in the either combinator
    try std.testing.expectError(Error.InvalidToken, result);
}
