const std = @import("std");
const builtin = @import("builtin");

pub fn cd_cmd(_: []const u8, arg: ?[]const u8, stdout: *std.io.Writer) void {
    const allocator = std.heap.page_allocator;

    const current_path = std.fs.cwd().realpathAlloc(allocator, ".") catch unreachable;
    defer allocator.free(current_path);

    const src_path = if (arg.?.len == 0) "." else arg.?;

    const path = if (src_path[0] == '/' or src_path[0] == '.' or src_path[0] == '~') allocator.dupe(u8, src_path) catch unreachable else std.fmt.allocPrint(allocator, "{s}/{s}", .{ current_path, src_path }) catch unreachable;

    defer allocator.free(path);

    var dir: std.fs.Dir = undefined;

    if (std.mem.startsWith(u8, path, ".")) {
        dir = std.fs.cwd().openDir(path, .{}) catch |err| {
            switch (err) {
                error.FileNotFound => {
                    stdout.print("cd: {s}: No such file or directory\n", .{src_path}) catch unreachable;
                    return;
                },
                else => |e| {
                    stdout.print("cd: {s}: {s}\n", .{ src_path, @errorName(e) }) catch unreachable;
                    return;
                },
            }
        };
    } else if (std.mem.startsWith(u8, path, "~")) {
        const home_name = if (builtin.target.os.tag == .windows) "USERPROFILE" else "HOME";
        const home = std.process.getEnvVarOwned(allocator, home_name) catch unreachable;
        defer allocator.free(home);

        dir = std.fs.openDirAbsolute(home, .{}) catch |err| {
            switch (err) {
                error.FileNotFound => {
                    stdout.print("cd: {s}: No such file or directory\n", .{home}) catch unreachable;
                    return;
                },
                else => |e| {
                    stdout.print("cd: {s}: {s}\n", .{ home, @errorName(e) }) catch unreachable;
                    return;
                },
            }
        };
    } else {
        dir = std.fs.openDirAbsolute(path, .{}) catch |err| {
            switch (err) {
                error.FileNotFound => {
                    stdout.print("cd: {s}: No such file or directory\n", .{src_path}) catch unreachable;
                    return;
                },
                else => |e| {
                    stdout.print("cd: {s}: {s}\n", .{ src_path, @errorName(e) }) catch unreachable;
                    return;
                },
            }
        };
    }
    defer dir.close();

    dir.setAsCwd() catch |err| {
        stdout.print("cd: {s}: {s}\n", .{ path, @errorName(err) }) catch unreachable;
        return;
    };
}
