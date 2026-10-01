const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const server = b.addExecutable(.{
        .name = "server",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/server.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(server);

    const client = b.addExecutable(.{
        .name = "client",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/client.zig"),
            .target = target,
            .optimize = optimize,
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
