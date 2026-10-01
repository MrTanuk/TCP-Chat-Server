const std = @import("std");
const Session = @import("session.zig");

pub fn main(init: std.process.Init) !void {
    const addr = try std.Io.net.IpAddress.parseIp4("127.0.0.1", 8080);

    var server = try addr.listen(init.io, .{ .mode = .stream });
    defer server.deinit(init.io);

    var stream = try server.accept(init.io);

    var session = try Session.create(init.gpa, init.io, &stream);
    defer session.deinit();

    try session.run("Cliente");
}
