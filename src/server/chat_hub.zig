const ChatHub = @This();

const std = @import("std");
const log = std.log;
const ServerConnection = @import("session.zig");

const Allocator = std.mem.Allocator;

allocator: Allocator,
io: std.Io,

num_ids: usize,
list_sessions: std.ArrayList(*ServerConnection),

pub fn create(allocator: Allocator, io: std.Io) !*ChatHub {
    var status_server = try allocator.create(ChatHub);
    errdefer allocator.destroy(status_server);

    status_server.allocator = allocator;
    status_server.io = io;
    status_server.list_sessions = .empty;

    status_server.num_ids = 0;

    return status_server;
}

pub fn destroy(self: *ChatHub) void {
    self.list_sessions.deinit(self.allocator);
    self.allocator.destroy(self);
}

pub fn appendClient(self: *ChatHub, session: *ServerConnection) !void {
    log.info("New client with id {}", .{self.num_ids});
    try self.list_sessions.append(self.allocator, session);
}

/// Receive the msg from a `ServerConnection` and the instance of itself
/// and print msg for all the `ServerConnection` instances saved in `list_sessions`
pub fn writeAllSockets(self: *ChatHub, msg: []u8, session: *ServerConnection) !void {
    const msg_ = msg[0 .. msg.len - 1]; // By the moment. It will change
    log.info("Client {d}: {s}", .{ session.id, msg_ });

    for (self.list_sessions.items) |s| {
        if (s == session) {
            continue;
        }

        s.sock_io.writer_stream.print("Client {d}: {s}", .{ session.id, msg }) catch continue;
        s.sock_io.writer_stream.flush() catch continue;
    }
}

pub fn removeClient(self: *ChatHub, session: *ServerConnection) !void {
    log.info("Client with id {} disconnected.", .{session.id});

    const id = std.mem.indexOfScalar(*ServerConnection, self.list_sessions.items, session) orelse return;
    _ = self.list_sessions.swapRemove(id);
}
