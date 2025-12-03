const std = @import("std");
const builtin = @import("builtin");

const builtin_cmd = std.StaticStringMap([]const u8).initComptime(.{
    .{ "exit", "" },
    .{ "echo", "" },
    .{ "type", "" },
    .{ "pwd", "" },
    .{ "cd", "" },
    .{ "clear", "" },
    .{ "cls", "" },
});

pub fn type_cmd(_command: []const u8, args: ?[]const u8, stdout: *std.io.Writer) void {
    const allocator = std.heap.page_allocator;
    const name = if (args) |a| a else _command;
    if (builtin_cmd.get(name)) |_| {
        stdout.print("{s} is a shell builtin\n", .{name}) catch unreachable;
    } else {
        const paths = std.process.getEnvVarOwned(allocator, "PATH") catch unreachable;
        defer allocator.free(paths);

        const delimiter = if (builtin.target.os.tag == .windows) ';' else ':';

        var path_dirs = std.mem.tokenizeScalar(u8, paths, delimiter);
        var found = false;

        while (path_dirs.next()) |dir| {
            const is_windows = builtin.os.tag == .windows;
            const t = if (is_windows) ".exe" else "";
            const abs_path = std.fmt.allocPrint(allocator, if (is_windows) "{s}\\{s}{s}" else "{s}/{s}{s}", .{ dir, name, t }) catch unreachable;
            defer allocator.free(abs_path);

            if (is_windows) {
                _ = std.fs.openFileAbsolute(abs_path, .{}) catch continue;
            } else {
                const stat = std.fs.cwd().statFile(abs_path) catch continue;
                const is_exec = (stat.mode & 0o111) != 0;
                if (!is_exec) continue;
            }

            stdout.print("{s} is {s}\n", .{ name, abs_path }) catch unreachable;
            found = true;
            return;
        }

        if (!found) stdout.print("{s}: not found\n", .{name}) catch unreachable;
    }
}
