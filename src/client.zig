const std = @import("std");
const Session = @import("session.zig");

pub fn main(init: std.process.Init) !void {
    const addr = try std.Io.net.IpAddress.parseIp4("127.0.0.1", 8080);

    var stream = try addr.connect(init.io, .{ .mode = .stream });

    var session = try Session.create(init.gpa, init.io, &stream);
    defer session.deinit();

    try session.run("Servidor");
}
