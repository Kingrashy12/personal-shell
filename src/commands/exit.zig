const std = @import("std");

pub fn exit_cmd(_: []const u8, args: ?[]const u8, stdout: *std.io.Writer) void {
    if (args) |a| {
        // simple numeric parse for single-digit exit codes, fallback to 1
        if (a.len == 1 and a[0] >= '0' and a[0] <= '9') {
            const code_u8: u8 = @as(u8, a[0] - '0');
            std.process.exit(code_u8);
        } else if (std.mem.eql(u8, a, "0")) {
            std.process.exit(0);
        } else {
            std.process.exit(1);
        }
    } else {
        stdout.print("Please specify a code.\n", .{}) catch unreachable;
    }
}
