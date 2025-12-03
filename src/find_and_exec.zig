const std = @import("std");
const builtin = @import("builtin");
const parser = @import("parser.zig");
const utils = @import("utils.zig");

pub fn findAndExecCommand(allocator: std.mem.Allocator, command: []const u8, args: []const u8, stdout: *std.io.Writer) !void {
    const paths = try std.process.getEnvVarOwned(allocator, "PATH");
    defer allocator.free(paths);

    const delimiter = if (builtin.target.os.tag == .windows) ';' else ':';
    var path_dirs = std.mem.tokenizeScalar(u8, paths, delimiter);

    var found = false;

    while (path_dirs.next()) |dir| {
        const is_windows = builtin.target.os.tag == .windows;
        const t = if (is_windows) ".exe" else "";
        const exe = std.fmt.allocPrint(allocator, if (is_windows) "{s}\\{s}{s}" else "{s}/{s}{s}", .{ dir, command, t }) catch unreachable;
        defer allocator.free(exe);

        if (is_windows) {
            _ = std.fs.openFileAbsolute(exe, .{}) catch continue;
        } else {
            const stats = std.fs.cwd().statFile(exe) catch continue;
            const is_exec = (stats.mode & 0o111) != 0;
            if (!is_exec) continue;
        }

        found = true;

        var child: std.process.Child = undefined;

        var args_list: std.ArrayList([]const u8) = .empty;
        defer args_list.deinit(allocator);

        try args_list.append(allocator, if (is_windows) exe else command);

        if (args.len > 0) {
            const parsed = parser.parseArgs(args, std.heap.page_allocator) catch unreachable;
            defer std.heap.page_allocator.free(parsed);

            for (parsed) |arg| {
                if (utils.isRedirectOut(arg)) break;
                try args_list.append(allocator, arg);
            }
        }

        child = std.process.Child.init(args_list.items, allocator);
        child.stdout_behavior = .Pipe;

        child.spawn() catch |err| {
            std.log.err("Failed to spawn child process: {s}\n", .{@errorName(err)});
            continue;
        };

        var reader = child.stdout.?.readerStreaming(&.{});
        var output_buffer: [1024]u8 = @splat(0);
        const len = try reader.interface.readSliceShort(&output_buffer);

        const wait_result = child.wait() catch |err| {
            std.log.err("Failed to wait for child process: {s}\n", .{@errorName(err)});
            continue;
        };

        try stdout.print("{s}", .{output_buffer[0..len]});

        switch (wait_result) {
            .Exited => |_| {},
            .Signal => |signal| std.log.err("Child process terminated by signal: {d}\n", .{signal}),
            .Stopped => |signal| std.log.err("Child process stopped by signal: {d}\n", .{signal}),
            else => std.log.err("Unknown wait result: {any}\n", .{wait_result}),
        }
        return;
    }

    if (!found) stdout.print("{s}: command not found\n", .{command}) catch unreachable;
}
