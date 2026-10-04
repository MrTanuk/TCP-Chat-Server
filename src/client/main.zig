const std = @import("std");

const ClientSession = @import("session.zig");

pub fn main(init: std.process.Init) !void {
    var threaded = std.Io.Threaded.init(init.gpa, .{});
    const io = threaded.io();

    var buffer_reader: [512]u8 = undefined;
    var stdin = std.Io.File.Reader.init(.stdin(), io, &buffer_reader);
    const reader = &stdin.interface;

    var buffer_writer: [512]u8 = undefined;
    var stdout = std.Io.File.Writer.init(.stdout(), io, &buffer_writer);
    const writer = &stdout.interface;

    _ = try writer.print("Write ip and port: ", .{});
    _ = try writer.flush();

    const ip_port = try reader.takeDelimiter('\n');

    if (ip_port) |value| {
        if (value.len == 0) {
            _ = try writer.print("Messed the ip. Try again\n.", .{});
            return error.EmptyInput;
        }
    } else {
        return error.EndOfLine;
    }

    const split_ip = std.mem.findScalar(u8, ip_port.?, ':');

    if (split_ip) |_| {} else {
        _ = try writer.print("Type correct uri: Ip + port\n.", .{});
        return error.EmptyInput;
    }

    const ip = ip_port.?[0..split_ip.?];
    const port_str = ip_port.?[split_ip.? + 1 ..];

    const port = try std.fmt.parseInt(u16, port_str, 10);

    const addr = try std.Io.net.IpAddress.parseIp4(ip, port);

    // stream variable life now is handled by ClientSession
    const stream = try addr.connect(io, .{ .mode = .stream });
    const client = try ClientSession.create(init.gpa, io, stream);
    defer client.destroy();

    var future1 = try io.concurrent(ClientSession.readFromServer, .{client});
    var future2 = try io.concurrent(ClientSession.writeToServer, .{client});

    _ = try future1.await(io);
    _ = try future2.await(io);
}
