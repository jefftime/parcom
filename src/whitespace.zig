const std = @import("std");
const parcom = @import("parcom.zig");
const Parser = parcom.Parser;
const Result = parcom.Result;
const Error = parcom.Error;
const InputType = parcom.InputType;
const end_of_stream_check = parcom.end_of_stream_check;
const String = parcom.String;

// TODO: Finish
// pub fn whitespace(input: InputType) Error!Result(String) {
//     try end_of_stream_check(input);
//     const allocator = parcom.ALLOCATOR orelse return Error.AllocatorNotSet;

//     var string_bytes = std.ArrayList(u8).initCapacity(
//         allocator,
//         parcom.STRING_DEFAULT_CAPACITY,
//     ) catch return Error.AllocationError;
//     for (input) |ch| {
//         if (!std.ascii.isWhitespace(ch)) break;
//         string_bytes.append(ch);
//     }
//     const result = String.new(string_bytes.items) catch {
//         return Error.AllocationError;
//     };

//     return .{
//         .input = input[string_bytes.len..],
//         .value = result,
//     };
// }

pub fn whitespace_ignore(input: InputType) Error!Result(struct {}) {
    var index: usize = 0;
    for (input) |ch| {
        if (!std.ascii.isWhitespace(ch)) break;
        index += 1;
    }
    return .{ .input = input[index..], .value = .{} };
}

////////////////////////////////////////
// SECTION: Tests
////////////////////////////////////////

test "whitespace_ignore multispace" {
    const result = try whitespace_ignore("   asdf");
    try std.testing.expectEqualStrings("asdf", result.input);
}

test "whitespace_ignore no spaces" {
    const result = try whitespace_ignore("asdf");
    try std.testing.expectEqualStrings("asdf", result.input);
}
