const std = @import("std");
const testing = std.testing;

pub const combinator = @import("combinator.zig");
pub const parser = @import("parser.zig");

////////////////////////////////////////
// Types
////////////////////////////////////////

pub const InputType = []const u8;
pub const String = struct {
    const StringSelf = @This();

    allocator: std.mem.Allocator,
    value: []const u8,

    pub fn new(
        allocator: std.mem.Allocator,
        string: []const u8,
    ) std.mem.Allocator.Error!String {
        const result = try allocator.alloc(u8, string.len);
        std.mem.copy(u8, result, string);
        return .{ .allocator = allocator, .value = result };
    }

    pub fn deinit(self: *String) void {
        self.allocator.free(self.value);
    }
};

pub var ALLOCATOR: ?std.mem.Allocator = null;
pub var STRING_DEFAULT_CAPACITY: usize = 64;

pub const Error = error{
    AllocatorNotSet,
    AllocationError,
    InvalidParse,
    InvalidToken,
    EndOfStream,
};

const ParseCheckError = error{
    InvalidType,
    InvalidParamCount,
    InvalidParamType,
    InvalidReturnTypeVoid,
    InvalidReturnType,
    NotAParser,
    Placeholder,
};

pub fn Parser(comptime T: anytype) type {
    return fn (input: InputType) Error!Result(T);
}

pub fn Result(comptime T: anytype) type {
    return struct { input: InputType, value: T };
}

////////////////////////////////////////
// Helper Functions
////////////////////////////////////////

pub fn get_return_type_multiple(comptime t: anytype) type {
    comptime {
        const ReturnType = get_return_type(t);

        const T = @TypeOf(t);
        const type_info = @typeInfo(T);

        return [type_info.Struct.fields.len]ReturnType;
    }
}

pub fn get_return_type(comptime t: anytype) type {
    comptime {
        const T = @TypeOf(t);
        const type_info = @typeInfo(T);

        var ReturnType: ?type = null;
        if (type_info == .Struct) {
            ReturnType = is_parser(t[0]) catch |err| {
                @compileLog(err);
                @compileError("Invalid parser in tuple (" ++ ")");
            };
            inline for (t) |prsr| {
                const CurReturnType = is_parser(prsr) catch |err| {
                    @compileLog(err);
                    @compileError("Not a parser!");
                };
                if (CurReturnType != ReturnType) {
                    @compileError("All members must have same return type");
                }
            }
        } else if (type_info == .Fn) {
            ReturnType = is_parser(t) catch |err| {
                // @compileLog(err);
                // @compileLog(@typeName(T));
                // @compileLog(type_info);
                // inline for (std.meta.declarations(T)) |decl| {
                //     s
                // }
                // @compileError(std.meta.declarations(T))
                @compileError(
                    std.fmt.comptimePrint(
                        "Invalid parser ({}): {}",
                        .{ @typeName(t), err },
                    ),
                );
            };
        } else {
            @compileError("Invalid parser type");
        }

        if (ReturnType) |rt| return rt;

        @compileError("Unable to get type for given parser");
    }
}

fn is_parser(comptime t: anytype) ParseCheckError!type {
    const T = @TypeOf(t);
    const type_info = @typeInfo(T);

    if (type_info != .Fn) return ParseCheckError.InvalidType;
    if (type_info.Fn.params.len != 1) return ParseCheckError.InvalidParamCount;
    if (type_info.Fn.params[0].type != InputType) {
        return ParseCheckError.InvalidParamType;
    }

    const return_type_info = @typeInfo(
        type_info.Fn.return_type orelse {
            return ParseCheckError.InvalidReturnTypeVoid;
        },
    );
    if (return_type_info != .ErrorUnion) {
        return ParseCheckError.InvalidReturnType;
    }
    const payload_info = @typeInfo(return_type_info.ErrorUnion.payload);
    if (payload_info != .Struct) return ParseCheckError.InvalidReturnType;
    var MaybeResultType: ?type = null;
    inline for (payload_info.Struct.fields) |field| {
        if (std.mem.eql(u8, "value", field.name)) {
            MaybeResultType = field.type;
        }
    }
    const ReturnType = MaybeResultType orelse {
        return ParseCheckError.InvalidReturnType;
    };

    if (T != Parser(ReturnType)) return ParseCheckError.NotAParser;

    return ReturnType;
}

pub fn end_of_stream_check(input: []const u8) Error!void {
    if (input.len == 0) return Error.EndOfStream;
}

fn parser_is_type(comptime t: anytype, comptime T: anytype) bool {
    const type_info = @typeInfo(@TypeOf(T));
    if (type_info != .Type) {
        @compileLog(type_info);
        @compileError("Expected type");
    }

    const ReturnType = is_parser(t) catch return false;
    if (ReturnType == T) return true;

    return false;
}

////////////////////////////////////////
// Tests
////////////////////////////////////////

test {
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(combinator);
    std.testing.refAllDecls(parser);
}

test "is_parser" {
    const impl = struct {
        fn parse(input: []const u8) Error!Result(u8) {
            return .{ .input = input, .value = 0 };
        }
    };

    try std.testing.expectEqual(Parser(u8), @TypeOf(impl.parse));

    const ResultType = is_parser(impl.parse) catch @panic("Invalid parser");
    try std.testing.expectEqual(u8, ResultType);
}

test "is_parser with complex type" {
    const ComplexType = struct { x: u32 };
    const impl = struct {
        fn parse(input: []const u8) Error!Result(ComplexType) {
            return .{ .input = input, .value = .{ .x = 0 } };
        }
    };

    try std.testing.expectEqual(Parser(ComplexType), @TypeOf(impl.parse));
    const ResultType = is_parser(impl.parse) catch @panic("Invalid parser");
    try std.testing.expectEqual(ComplexType, ResultType);
}

test "is_parser parser with invalid params" {
    const invalid_parser = struct {
        fn parse() Error!Result(u8) {
            return .{ .input = "", .value = 0 };
        }
    };

    const result = is_parser(invalid_parser.parse) catch |err| err;
    try std.testing.expectEqual(ParseCheckError.InvalidParamCount, result);
}

test "is_parser parser with invalid slice type" {
    const invalid_parser = struct {
        fn parse(input: []const u32) Error!Result(u8) {
            _ = input;
            return .{ .input = "", .value = 0 };
        }
    };

    const result = is_parser(invalid_parser.parse) catch |err| err;
    try std.testing.expectEqual(ParseCheckError.InvalidParamType, result);
}

test "is_parser with invalid return type" {
    const invalid_parser = struct {
        fn parse(input: []const u8) void {
            _ = input;
        }
    };

    const result = is_parser(invalid_parser.parse) catch |err| err;
    try std.testing.expectEqual(ParseCheckError.InvalidReturnType, result);
}
