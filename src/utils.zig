const std = @import("std");
const builtin = @import("builtin");

pub const ANSI_RESET = "\x1b[0m";
pub const ANSI_GREEN = "\x1b[32m";
pub const ANSI_MAGENTA = "\x1b[35m";
pub const ANSI_YELLOW = "\x1b[33m";
pub const ANSI_BLUE = "\x1b[34m";
pub const ANSI_BOLD = "\x1b[1m";
pub const ANSI_CYAN = "\x1b[36m";

pub fn readLine(allocator: std.mem.Allocator, comptime max_size: usize, to_lower: bool) ![]u8 {
    var stdin_buffer: [max_size]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;

    // Get raw input
    const line = try stdin.takeDelimiterExclusive('\n');

    // Allocate a safe copy
    const result = try allocator.alloc(u8, line.len);
    @memcpy(result, line);

    // Optionally lowercase
    if (to_lower) {
        for (result) |*c| {
            c.* = std.ascii.toLower(c.*);
        }
    }

    return result;
}

pub fn isRedirectOut(symbol: []const u8) bool {
    return std.mem.eql(u8, "1>", symbol) or std.mem.eql(u8, ">", symbol);
}

pub fn print_dir(allocator: std.mem.Allocator, writer: anytype) void {
    const dir_path = std.fs.cwd().realpathAlloc(allocator, ".") catch unreachable;
    defer allocator.free(dir_path);

    // windows: USERNAME
    // linux/macos: USER

    var env = std.process.getEnvMap(allocator) catch unreachable;
    defer env.deinit();

    var home_dir: []const u8 = "";
    var final_dir: []const u8 = "";

    if (builtin.os.tag == .windows) {
        home_dir = std.fmt.allocPrint(allocator, "C:\\Users\\{s}", .{env.get("USERNAME") orelse ""}) catch unreachable;
        defer allocator.free(home_dir);

        final_dir = std.mem.replaceOwned(u8, allocator, dir_path, home_dir, "~") catch unreachable;
    } else if (builtin.os.tag == .linux or builtin.os.tag == .macos) {
        home_dir = env.get("HOME") orelse "";
        final_dir = std.mem.replaceOwned(u8, allocator, dir_path, home_dir, "~") catch unreachable;
    } else {
        final_dir = try std.mem.dupe(u8, allocator, dir_path);
    }
    writer.print("{s}{s}{s} ", .{ ANSI_MAGENTA, final_dir, ANSI_RESET }) catch unreachable;
    defer allocator.free(final_dir);
}
