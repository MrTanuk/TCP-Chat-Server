const std = @import("std");

const ClientSession = @import("session.zig");
const address = @import("net").address;

pub fn main(init: std.process.Init) !void {
    var threaded = std.Io.Threaded.init(init.gpa, .{});
    const io = threaded.io();

    const bind_addr: address.AddressMode = .loopback;
    _ = bind_addr;

    const addr_mode = try address.chooseMode(io);
    const addr = try address.resolveAddress(io, addr_mode, 8080);

    // stream variable life now is handled by ClientSession
    const stream = try addr.connect(io, .{ .mode = .stream });
    const client = try ClientSession.create(init.gpa, io, stream);
    defer client.destroy();

    var buffer: [128]u8 = undefined;
    var w = std.Io.File.Writer.init(.stdout(), io, &buffer);

    _ = try w.interface.print("Conected successfuly at {f}\n", .{client.sock_stream.socket.address});
    _ = try w.interface.flush();

    var future1 = try io.concurrent(ClientSession.readFromServer, .{client});
    var future2 = try io.concurrent(ClientSession.writeToServer, .{client});

    _ = try future1.await(io);

    _ = try future2.await(io);
}
