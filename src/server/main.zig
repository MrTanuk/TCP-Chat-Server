const std = @import("std");

const TcpListener = @import("listener.zig");
const ChatHub = @import("chat_hub.zig");
const address = @import("net").address;

const Stream = std.Io.net.Stream;
const Allocator = std.mem.Allocator;

pub fn main(init: std.process.Init) !void {
    var threaded = std.Io.Threaded.init(init.gpa, .{});
    defer threaded.deinit();

    const io = threaded.io();

    const chat_hub = try ChatHub.create(init.gpa, io);
    defer chat_hub.destroy();

    const addr_mode = try address.chooseMode(io);
    const addr = try address.resolveAddress(io, addr_mode, 8080);
    // La vida del server pasa a
    // server variable now is handled by TcpListener
    var server = try addr.listen(io, .{ .mode = .stream, .reuse_address = true });

    var tcp_listener = TcpListener.init(init.gpa, io, &server);
    defer tcp_listener.deinit();

    var future = try io.concurrent(TcpListener.listen, .{ &tcp_listener, chat_hub });

    _ = try future.await(io);
}
