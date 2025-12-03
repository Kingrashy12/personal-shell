const std = @import("std");

pub fn pwd_cmd(_: []const u8, _: ?[]const u8, stdout: *std.io.Writer) void {
    const pwd = std.fs.cwd().realpathAlloc(std.heap.page_allocator, ".") catch unreachable;
    defer std.heap.page_allocator.free(pwd);
    stdout.print("{s}\n", .{pwd}) catch unreachable;
}
