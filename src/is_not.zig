const std = @import("std");
const parcom = @import("parcom.zig");
const Parser = parcom.Parser;
const Result = parcom.Result;
const Error = parcom.Error;
const InputType = parcom.InputType;

pub fn is_not(comptime str: InputType) Parser(InputType) {
    _ = str;
    unreachable;
}

////////////////////////////////////////
// SECTION: Tests
////////////////////////////////////////

test "is_not valid" {}

test "is_not invalid" {}
