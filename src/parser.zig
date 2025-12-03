const std = @import("std");

const State = enum {
    normal,
    single_quote,
};

pub fn parseArgs(
    input: []const u8,
    allocator: std.mem.Allocator,
) ![][]const u8 {
    var tokens: std.ArrayList([]const u8) = .empty;
    var buf: std.ArrayList(u8) = .empty;

    var in_single = false;
    var in_double = false;

    var i: usize = 0;

    while (i < input.len) {
        const c = input[i];

        // -------------------------
        // handle backslash escaping
        // -------------------------
        if (c == '\\' and i + 1 < input.len) {
            if (!in_single and !in_double) {
                // outside quotes → escape next character
                try buf.append(allocator, input[i + 1]);
                i += 2;
                continue;
            } else if (in_double) {
                if (input[i + 1] == '\\' or input[i + 1] == '"' or input[i + 1] == '$' or input[i + 1] == '`' or input[i + 1] == '\n') {
                    try buf.append(allocator, input[i + 1]);
                    i += 2;
                    continue;
                }
                // backslash literal
                try buf.append(allocator, '\\');
                try buf.append(allocator, input[i + 1]);
                i += 2;
                continue;
            } else {
                // inside quotes → keep backslash literally
                try buf.append(allocator, c);
                i += 1;
                continue;
            }
        }

        switch (c) {
            '\'' => {
                if (!in_double) {
                    in_single = !in_single;
                } else {
                    try buf.append(allocator, c);
                }
                i += 1;
                continue;
            },
            '"' => {
                if (!in_single) {
                    in_double = !in_double;
                } else {
                    try buf.append(allocator, c);
                }
                i += 1;
                continue;
            },
            ' ' => {
                if (in_single or in_double) {
                    try buf.append(allocator, c);
                } else if (buf.items.len > 0) {
                    try tokens.append(allocator, try buf.toOwnedSlice(allocator));
                    buf.clearRetainingCapacity();
                }
                i += 1;
                continue;
            },
            '\n' => break,

            else => {
                try buf.append(allocator, c);
                i += 1;
                continue;
            },
        }
    }

    if (buf.items.len > 0) {
        try tokens.append(allocator, try buf.toOwnedSlice(allocator));
    }

    return try tokens.toOwnedSlice(allocator);
}

pub const ParseResult = struct {
    name: []const u8,
    args: ?[]const u8,
};

pub fn parseCommand(command: []const u8) ParseResult {
    // skip leading spaces
    var start: usize = 0;
    while (start < command.len and command[start] == ' ') : (start += 1) {}

    if (start >= command.len) {
        return ParseResult{ .name = command[0..0], .args = null };
    }

    var name: []const u8 = undefined;
    var args_start: usize = undefined;

    // Check if the executable name is quoted
    if (command[start] == '"' or command[start] == '\'') {
        const quote = command[start];
        var end: usize = start + 1;

        // Find the closing quote
        while (end < command.len and command[end] != quote) : (end += 1) {}

        if (end >= command.len) {
            // No closing quote found, treat as unquoted
            name = command[start..];
            args_start = command.len;
        } else {
            // Extract name without quotes
            name = command[start + 1 .. end];
            args_start = end + 1;
        }
    } else {
        // Original logic for unquoted names
        if (std.mem.indexOf(u8, command[start..], " ")) |pos| {
            name = command[start..][0..pos];
            args_start = start + pos + 1;
        } else {
            name = command[start..];
            args_start = command.len;
        }
    }

    // Skip spaces before args
    while (args_start < command.len and command[args_start] == ' ') : (args_start += 1) {}

    if (args_start < command.len) {
        return ParseResult{ .name = name, .args = command[args_start..] };
    }
    return ParseResult{ .name = name, .args = null };
}
