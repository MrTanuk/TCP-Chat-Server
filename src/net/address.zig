const std = @import("std");

pub const AddressMode = enum {
    loopback,
    lan,
};

pub fn inputAddress(io: std.Io) !std.Io.net.IpAddress {
    var buffer_reader: [512]u8 = undefined;
    var stdin = std.Io.File.Reader.init(.stdin(), io, &buffer_reader);
    const reader = &stdin.interface;

    var buffer_writer: [512]u8 = undefined;
    var stdout = std.Io.File.Writer.init(.stdout(), io, &buffer_writer);
    const writer = &stdout.interface;

    _ = try writer.print("Write address: ", .{});
    _ = try writer.flush();

    const addr_user = try reader.takeDelimiter('\n') orelse return error.EndOfInput;

    if (addr_user.len == 0)
        return error.EmptyInput;

    const idx_colon = std.mem.findScalar(u8, addr_user, ':') orelse return error.InvalidAddress;

    const ip = addr_user[0..idx_colon];
    const port_str = addr_user[idx_colon + 1 ..];

    const port = try std.fmt.parseInt(u16, port_str, 10);
    const addr = try std.Io.net.IpAddress.parseIp4(ip, port);

    return addr;
}

pub fn chooseMode(io: std.Io) !AddressMode {
    var buffer_reader: [128]u8 = undefined;
    var stdin = std.Io.File.Reader.init(.stdin(), io, &buffer_reader);
    const reader = &stdin.interface;

    var buffer_writer: [128]u8 = undefined;
    var stdout = std.Io.File.Writer.init(.stdout(), io, &buffer_writer);
    const writer = &stdout.interface;

    _ = try writer.print("1. loopback (default).\n2. lan.\nChoose: ", .{});
    _ = try writer.flush();

    const input_addr = try reader.takeDelimiter('\n') orelse return error.EndOfInput;
    const trimmed = std.mem.trim(u8, input_addr, " \r\t");

    if (trimmed.len == 0) {
        return .loopback;
    } else if (std.mem.eql(u8, trimmed, "1") or std.mem.eql(u8, trimmed, "loopback")) {
        return .loopback;
    } else if (std.mem.eql(u8, trimmed, "2") or std.mem.eql(u8, trimmed, "lan")) {
        return .lan;
    }

    return error.InvalidChoice;
}

pub fn resolveAddress(io: std.Io, mode: AddressMode, port: u16) !std.Io.net.IpAddress {
    return switch (mode) {
        .loopback => std.Io.net.IpAddress.parseIp4("127.0.0.1", port),
        .lan => inputAddress(io),
    };
}
