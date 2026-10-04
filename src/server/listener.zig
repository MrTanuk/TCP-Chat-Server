const TcpListener = @This();

const std = @import("std");
const ChatHub = @import("chat_hub.zig");
const ServerConnection = @import("session.zig");

const Allocator = std.mem.Allocator;

allocator: Allocator,
io: std.Io,

server: *std.Io.net.Server,

pub fn init(allocator: Allocator, io: std.Io, server: *std.Io.net.Server) TcpListener {
    return .{ .allocator = allocator, .io = io, .server = server };
}

/// Waiting for a client socket to create a `ServerConnection` instance,
/// saving in a list in `ChatHub` instance and running the `ServerConnection` instance.
pub fn listen(self: *TcpListener, chat_hub: *ChatHub) !void {
    while (true) {
        // stream variable life  is handle by session
        const stream = try self.server.accept(self.io);

        chat_hub.num_ids += 1;
        const id = chat_hub.num_ids;

        const session = try ServerConnection.create(self.allocator, self.io, chat_hub, stream, id);
        try chat_hub.appendClient(session);

        _ = try self.io.concurrent(ServerConnection.run, .{session});
    }
}

pub fn deinit(self: *TcpListener) void {
    self.server.deinit(self.io);
}
