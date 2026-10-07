const ClientConnection = @This();

const std = @import("std");
const SocketIo = @import("net").socket_io.SocketIo;

const Allocator = std.mem.Allocator;

io: std.Io,
allocator: Allocator,

sock_stream: std.Io.net.Stream,
sock_io: SocketIo, // Contains reader_stream and writer_stream

stdin_io: std.Io.File.Reader,
stdout_io: std.Io.File.Writer,

// I/O interface
reader_io: *std.Io.Reader,
writer_io: *std.Io.Writer,

stdin_buf: [2048]u8 = undefined,
stdout_buf: [2048]u8 = undefined,

/// Input the message to send to Server (stdin -> socket).
pub fn writeToServer(client: *ClientConnection) !void {
    while (true) {
        const msg = try client.reader_io.takeDelimiterInclusive('\n');
        if (msg.len == 0) continue;

        client.sock_io.writer_stream.writeAll(msg) catch return;
        client.sock_io.writer_stream.flush() catch return;
    }
}

/// Receive the message from server and print it (socket -> stdout).
pub fn readFromServer(client: *ClientConnection) !void {
    while (true) {
        const msg = client.sock_io.reader_stream.takeDelimiterInclusive('\n') catch return;

        _ = try client.writer_io.print("{s}", .{msg});
        _ = try client.writer_io.flush();
    }
}

pub fn create(allocator: Allocator, io: std.Io, stream: std.Io.net.Stream) !*ClientConnection {
    var client = try allocator.create(ClientConnection);
    errdefer allocator.destroy(client);

    client.allocator = allocator;
    client.io = io;

    client.sock_stream = stream;

    // Reader and Writer for stdin and stdout
    client.stdin_io = std.Io.File.Reader.init(.stdin(), io, &client.stdin_buf);
    client.reader_io = &client.stdin_io.interface;
    client.stdout_io = std.Io.File.Writer.init(.stdout(), io, &client.stdout_buf);
    client.writer_io = &client.stdout_io.interface;

    // Reader and Writer within the stream socket
    client.sock_io.read_state = client.sock_stream.reader(io, &client.sock_io.sock_r_buf);
    client.sock_io.reader_stream = &client.sock_io.read_state.interface;
    client.sock_io.write_state = client.sock_stream.writer(io, &client.sock_io.sock_w_buf);
    client.sock_io.writer_stream = &client.sock_io.write_state.interface;

    return client;
}

pub fn destroy(session: *ClientConnection) void {
    session.sock_stream.close(session.io);
    session.allocator.destroy(session);
}
