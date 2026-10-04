const SocketIO = @This();

const std = @import("std");

read_state: std.Io.net.Stream.Reader,
write_state: std.Io.net.Stream.Writer,

// I/O stream interface
reader_stream: *std.Io.Reader,
writer_stream: *std.Io.Writer,

sock_w_buf: [2048]u8 = undefined,
sock_r_buf: [2048]u8 = undefined,
