const std = @import("std");

const ClientSession = @import("session.zig");

pub fn main(init: std.process.Init) !void {
    var threaded = std.Io.Threaded.init(init.gpa, .{});
    const io = threaded.io();

    const addr = try std.Io.net.IpAddress.parseIp4("127.0.0.1", 8080);

    // stream variable life now is handled by ClientSession
    const stream = try addr.connect(io, .{ .mode = .stream, });
    const client = try ClientSession.create(init.gpa, io, stream);
    defer client.destroy();

    var future1 = try io.concurrent(ClientSession.readFromServer, .{client});
    var future2 = try io.concurrent(ClientSession.writeToServer, .{client});

    _ = try future1.await(io);
    _ = try future2.await(io);
}
