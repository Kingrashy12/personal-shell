const std = @import("std");
const parser = @import("../parser.zig");
const utils = @import("../utils.zig");

pub fn echo(_: []const u8, args: ?[]const u8, stdout: *std.io.Writer) void {
    if (args) |a| {
        const args_str = parser.parseArgs(a, std.heap.page_allocator) catch unreachable;
        defer std.heap.page_allocator.free(args_str);

        for (args_str) |value| {
            if (utils.isRedirectOut(value)) {
                break;
            } else stdout.print("{s} ", .{value}) catch unreachable;
        }
        stdout.print("\n", .{}) catch unreachable;
    } else {
        stdout.print("\n", .{}) catch unreachable;
    }
}
