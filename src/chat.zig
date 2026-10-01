const std = @import("std");

/// Read from`reader` y write in `writer` (stdin -> socket).
/// Here the socket takes the input to send messages
pub fn pumpInput(reader: *std.Io.Reader, writer: *std.Io.Writer) !void {
    while (true) {
        const msg = try reader.takeDelimiterInclusive('\n');
        try writer.writeAll(msg);
        try writer.flush();
    }
}

/// Read from `reader` remote and write in `writer` with a prefix (socket -> stdout).
/// `label` is, for example, "Server" o "Client".
pub fn pumpOutput(
    reader: *std.Io.Reader,
    writer: *std.Io.Writer,
    label: []const u8,
) !void {
    while (true) {
        const maybe = try reader.takeDelimiter('\n');
        if (maybe) |msg| {
            try writer.print("{s}: {s}\n", .{ label, msg });
            try writer.flush();
        }
    }
}
