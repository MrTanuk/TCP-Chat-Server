const ClientConnection = @This();

const std = @import("std");
const SocketIO = @import("socket_io");

const Allocator = std.mem.Allocator;

io: std.Io,
allocator: Allocator,
sock_stream: std.Io.net.Stream,
sock_io: SocketIO, // Contains reader_stream and writer_stream

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
        try client.sock_io.writer_stream.writeAll(msg);
        try client.sock_io.writer_stream.flush();
    }
}

/// Receive the message from server and print it (socket -> stdout).
pub fn readFromServer(client: *ClientConnection) !void {
    while (true) {
        const msg = client.sock_io.reader_stream.takeDelimiterInclusive('\n') catch {
            client.destroy();
            return;
        };

        try client.writer_io.print("{s}:n", .{msg});
        try client.writer_io.flush();
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
