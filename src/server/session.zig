const ServerConnection = @This();

const std = @import("std");
const ChatHub = @import("chat_hub.zig");
const SocketIo = @import("net").socket_io.SocketIo;

const Allocator = std.mem.Allocator;

id: usize,

io: std.Io,
allocator: Allocator,
chat_hub: *ChatHub,

sock_stream: std.Io.net.Stream,
sock_io: SocketIo,

pub fn create(allocator: Allocator, io: std.Io, chat_hub: *ChatHub, sock_stream: std.Io.net.Stream, id: usize) !*ServerConnection {
    var stream = try allocator.create(ServerConnection);
    errdefer allocator.destroy(stream);

    stream.id = id;

    stream.io = io;
    stream.allocator = allocator;
    stream.sock_stream = sock_stream;
    stream.chat_hub = chat_hub;

    // Socket stream Reader and Writer
    stream.sock_io.read_state = stream.sock_stream.reader(io, &stream.sock_io.sock_r_buf);
    stream.sock_io.reader_stream = &stream.sock_io.read_state.interface;
    stream.sock_io.write_state = stream.sock_stream.writer(io, &stream.sock_io.sock_w_buf);
    stream.sock_io.writer_stream = &stream.sock_io.write_state.interface;

    return stream;
}

/// The section where the `ServerConnection` runs its tasks
/// By the moment, its unique task is input the msg to server (stdin -> socket).
pub fn run(self: *ServerConnection) !void {
    while (true) {
        const msg = self.sock_io.reader_stream.takeDelimiterInclusive('\n') catch {
            _ = try self.chat_hub.removeClient(self);
            self.destroy();
            return;
        };

        try self.chat_hub.writeAllSockets(msg, self);
    }
}

pub fn destroy(self: *ServerConnection) void {
    self.sock_stream.close(self.io);
    self.allocator.destroy(self);
}
