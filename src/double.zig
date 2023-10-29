const std = @import("std");
const parcom = @import("parcom.zig");
const Result = parcom.Result;
const Error = parcom.Error;
const InputType = parcom.InputType;
const end_of_stream_check = parcom.end_of_stream_check;
const one_of = parcom.parser.one_of;
const maybe = parcom.combinator.maybe;
const many = parcom.combinator.many;
const tag = parcom.parser.tag;
const digits = parcom.parser.digits;

// TODO: Allow for exponent
pub fn double(input: InputType) Error!Result(f64) {
    try end_of_stream_check(input);

    const negative_result = try maybe(tag("-"))(input);
    const negative = if (negative_result.value != null) true else false;

    const double_results = try many(one_of("0123456789."))(
        negative_result.input,
    );
    defer double_results.value.deinit();

    var result = std.fmt.parseFloat(f64, double_results.value.items) catch {
        return Error.InvalidParse;
    };

    if (negative) result = -result;
    return .{ .input = double_results.input, .value = result };
}

////////////////////////////////////////
// SECTION: Tests
////////////////////////////////////////

const EPSILON = @sqrt(std.math.floatEps(f64));

test "double valid" {
    const result = try double("-0.1");
    try std.testing.expectEqualStrings("", result.input);
    try std.testing.expectApproxEqAbs(@as(f64, -0.1), result.value, EPSILON);
}

test "double valid 2" {
    const result = try double("-.1");
    try std.testing.expectEqualStrings("", result.input);
    try std.testing.expectApproxEqAbs(@as(f64, -0.1), result.value, EPSILON);
}

test "double valid 3" {
    const result = try double("0.1");
    try std.testing.expectEqualStrings("", result.input);
    try std.testing.expectApproxEqAbs(@as(f64, 0.1), result.value, EPSILON);
}

test "double valid 4" {
    const result = try double(".1");
    try std.testing.expectEqualStrings("", result.input);
    try std.testing.expectApproxEqAbs(@as(f64, 0.1), result.value, EPSILON);
}

test "double valid 5" {
    const result = try double("10");
    try std.testing.expectEqualStrings("", result.input);
    try std.testing.expectApproxEqAbs(@as(f64, 10.0), result.value, EPSILON);
}

test "double valid 6" {
    const result = try double("-10");
    try std.testing.expectEqualStrings("", result.input);
    try std.testing.expectApproxEqAbs(@as(f64, -10.0), result.value, EPSILON);
}

test "double invalid" {
    const result = double("abc");
    try std.testing.expectError(Error.InvalidToken, result);
}

test "double invalid 2" {
    const result = double("-abc");
    try std.testing.expectError(Error.InvalidToken, result);
}

test "double invalid 3" {
    const result = double("10..01");
    try std.testing.expectError(Error.InvalidParse, result);
}
