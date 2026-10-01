const Session = @This();
const std = @import("std");
const chat = @import("chat.zig");
const Allocator = std.mem.Allocator;

io: std.Io,
allocator: Allocator,

sock_stream: *std.Io.net.Stream,

stdin_io: std.Io.File.Reader,
stdout_io: std.Io.File.Writer,

// I/O interface
reader_io: *std.Io.Reader,
writer_io: *std.Io.Writer,

stdin_stream: std.Io.net.Stream.Reader,
stdout_stream: std.Io.net.Stream.Writer,

// I/O stream interface
reader_stream: *std.Io.Reader,
writer_stream: *std.Io.Writer,

stdin_buf: [4096]u8 = undefined,
stdout_buf: [4096]u8 = undefined,
sock_w_buf: [4096]u8 = undefined,
sock_r_buf: [4096]u8 = undefined,

pub fn create(allocator: Allocator, io: std.Io, sock_stream: *std.Io.net.Stream) !*Session {
    var stream = try allocator.create(Session);
    errdefer allocator.destroy(stream);

    stream.io = io;
    stream.allocator = allocator;
    stream.sock_stream = sock_stream;

    // I/O Reader and Writer
    stream.stdin_io = std.Io.File.Reader.init(.stdin(), stream.io, &stream.stdin_buf);
    stream.reader_io = &stream.stdin_io.interface;
    stream.stdout_io = std.Io.File.Writer.init(.stdout(), stream.io, &stream.stdout_buf);
    stream.writer_io = &stream.stdout_io.interface;

    // Socket stream Reader and Writer
    stream.stdin_stream = stream.sock_stream.reader(stream.io, &stream.sock_r_buf);
    stream.reader_stream = &stream.stdin_stream.interface;
    stream.stdout_stream = stream.sock_stream.writer(stream.io, &stream.sock_w_buf);
    stream.writer_stream = &stream.stdout_stream.interface;

    return stream;
}

pub fn deinit(session: *Session) void {
    session.sock_stream.close(session.io);
    session.allocator.destroy(session);
}

/// Runs a complete chat session over an already connected stream.
/// The stream is borrowed: the caller is responsible for closing it.
/// remote_label is how what arrives from the other side is labeled.
pub fn run(
    session: *Session,
    remote_label: []const u8,
) !void {
    // Two threads: one pushes stdin -> socket, the other pulls socket -> stdout.
    const t_in = try std.Thread.spawn(
        .{},
        chat.pumpInput,
        .{ session.reader_io, session.writer_stream },
    );
    const t_out = try std.Thread.spawn(
        .{},
        chat.pumpOutput,
        .{ session.reader_stream, session.writer_io, remote_label },
    );

    t_in.join();
    t_out.join();
}
