const std = @import("std");
const parcom = @import("parcom.zig");
const InputType = parcom.InputType;
const Error = parcom.Error;
const Parser = parcom.Parser;
const Result = parcom.Result;

// pub const whitespace = @import("whitespace.zig").whitespace;
pub const whitespace_ignore = @import("whitespace.zig").whitespace_ignore;
pub const tag = @import("tag.zig").tag;
pub const one_of = @import("one_of.zig").one_of;
pub const is_not = @import("is_not.zig").is_not;
pub const digits = @import("digits.zig").digits;
pub const number = @import("number.zig").number;
pub const double = @import("double.zig").double;

////////////////////////////////////////
// SECTION: Tests
////////////////////////////////////////

test {
    std.testing.refAllDecls(@This());
}
