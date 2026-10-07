const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const net_mod = b.addModule("net", .{
        .root_source_file = b.path("src/net/net.zig"),
        .target = target,
        .optimize = optimize,
    });

    const server = b.addExecutable(.{
        .name = "server",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/server/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{
                    .name = "net",
                    .module = net_mod,
                },
            },
        }),
    });
    b.installArtifact(server);

    const client = b.addExecutable(.{
        .name = "client",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/client/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{
                    .name = "net",
                    .module = net_mod,
                },
            },
        }),
    });
    b.installArtifact(client);

    const run_server = b.addRunArtifact(server);
    run_server.step.dependOn(b.getInstallStep());
    b.step("run-server", "Run the server").dependOn(&run_server.step);

    const run_client = b.addRunArtifact(client);
    run_client.step.dependOn(b.getInstallStep());
    b.step("run-client", "Run the client").dependOn(&run_client.step);
}
