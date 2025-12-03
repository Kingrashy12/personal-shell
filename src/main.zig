const std = @import("std");
const builtin = @import("builtin");
const parser = @import("parser.zig");
const utils = @import("utils.zig");
const commands = @import("commands/root.zig");
const readLine = utils.readLine;
const findAndExecCommand = @import("find_and_exec.zig").findAndExecCommand;

const CommandFn = fn (command: []const u8, args: ?[]const u8, stdout: *std.io.Writer) void;

fn clear(_: []const u8, _: ?[]const u8, stdout: *std.io.Writer) void {
    stdout.print("\x1B[2J\x1B[3J\x1B[H", .{}) catch unreachable;
}

const builtin_cmd = std.StaticStringMap(*const CommandFn).initComptime(.{
    .{ "exit", commands.exit_cmd },
    .{ "echo", commands.echo_cmd },
    .{ "type", commands.type_cmd },
    .{ "pwd", commands.pwd_cmd },
    .{ "cd", commands.cd_cmd },
    .{ "clear", clear },
    .{ "cls", clear },
});

pub fn main() !void {
    var stdout_buf: [512]u8 = @splat(0);
    var stdout_writer = std.fs.File.stdout().writerStreaming(&stdout_buf);
    var stdout = &stdout_writer.interface;
    // iterative REPL loop: create a short-lived arena per command to avoid long recursion and leaks
    while (true) {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        // ensure deinit each iteration
        defer arena.deinit();

        const allocator = arena.allocator();

        utils.print_dir(allocator, stdout);
        try stdout.print("$ ", .{});
        try stdout.flush();

        const command = try readLine(allocator, 4096, false);

        const trimmed = std.mem.trim(u8, command, "\r");

        // parse the command into name and args; name references the owned slice
        const name_and_args = parser.parseCommand(trimmed);
        const name = name_and_args.name;
        const args = name_and_args.args orelse "";

        if (builtin_cmd.get(name)) |action| {
            action(trimmed, args, stdout);
        } else {
            try findAndExecCommand(allocator, name, args, stdout);
        }

        var arg_iter = std.mem.tokenizeScalar(u8, args, ' ');

        while (arg_iter.next()) |arg| {
            if (utils.isRedirectOut(arg)) {
                const redirect_file = arg_iter.next().?;
                const file = if (!std.mem.startsWith(u8, redirect_file, "/"))
                    try std.fs.cwd().createFile(redirect_file, .{})
                else
                    try std.fs.createFileAbsolute(redirect_file, .{});
                defer file.close();

                try file.writeAll(stdout.buffered());
                _ = stdout.consumeAll();
            }
        }

        try stdout.flush();
    }
}
