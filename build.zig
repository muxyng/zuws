const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const debug_logs = b.option(bool, "debug_logs", "Whether to enable debug logs for route creation.") orelse (optimize == .Debug);
    const with_proxy = b.option(bool, "with_proxy", "Whether to enable PROXY Protocol v2 support.") orelse false;

    const config_options = b.addOptions();
    config_options.addOption(bool, "debug_logs", debug_logs);
    config_options.addOption(bool, "is_ssl", false);

    const uSockets = b.addLibrary(.{
        .name = "uSockets",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    uSockets.link_function_sections = true;
    uSockets.link_data_sections = true;
    uSockets.link_gc_sections = true;

    const u_sockets_root = b.path("uWebSockets/uSockets/src");
    uSockets.root_module.addIncludePath(u_sockets_root);
    uSockets.installHeader(b.path("uWebSockets/uSockets/src/libusockets.h"), "libusockets.h");

    uSockets.root_module.addCSourceFiles(.{
        .root = u_sockets_root,
        .files = &.{
            "bsd.c",
            "context.c",
            "loop.c",
            "quic.c",
            "socket.c",
            "udp.c",
            "crypto/sni_tree.cpp",
            "eventing/epoll_kqueue.c",
        },
        .flags = &.{"-DLIBUS_NO_SSL"},
    });

    const uws = b.addTranslateC(.{
        .root_source_file = b.path("bindings/uws.h"),
        .target = target,
        .optimize = optimize,
    });
    uws.defineCMacro("ZUWS_USE_SSL", "0");

    var uws_flags = try std.ArrayList([]const u8).initCapacity(b.allocator, 3);
    try uws_flags.append(b.allocator, "-DUWS_NO_ZLIB");
    if (with_proxy) try uws_flags.append(b.allocator, "-DUWS_WITH_PROXY");

    const uWebSockets = uws.addModule("uws");
    uWebSockets.link_libcpp = true;
    uWebSockets.linkLibrary(uSockets);
    uWebSockets.addCSourceFiles(.{
        .root = b.path("bindings/"),
        .files = &.{"uws.cpp"},
        .flags = try uws_flags.toOwnedSlice(b.allocator),
    });

    const zuws = b.addModule("zuws", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    zuws.addOptions("config", config_options);
    zuws.addImport("uws", uWebSockets);

    const libzuws = b.addLibrary(.{
        .name = "zuws",
        .linkage = .static,
        .root_module = zuws,
    });
    b.installArtifact(libzuws);

    const example_step = b.step("example", "Build and run an example.");
    const example_assembly_step = b.step("example-asm", "Build and emit an example's assembly.");

    const export_test = b.addTest(.{
        .root_module = zuws,
    });
    const run_export_test = b.addRunArtifact(export_test);

    const test_step = b.step("test", "Run unit tests on the exports");
    test_step.dependOn(&run_export_test.step);

    if (b.args) |args| {
        const example_name = args[0];
        const path = try std.fmt.allocPrint(b.allocator, "examples/{s}/main.zig", .{example_name});

        const io = std.Options.debug_io;
        try std.Io.Dir.cwd().access(io, path, .{});

        const exe = b.addExecutable(.{
            .name = example_name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(path),
                .target = target,
                .optimize = optimize,
            }),
        });

        exe.root_module.addImport("uws", uWebSockets);
        exe.root_module.addImport("zuws", zuws);
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        example_step.dependOn(&run_cmd.step);

        const asm_description = try std.fmt.allocPrint(b.allocator, "Emit the {s} example ASM file", .{example_name});
        const asm_step_name = try std.fmt.allocPrint(b.allocator, "{s}-asm", .{example_name});
        const asm_step = b.step(asm_step_name, asm_description);

        const awf = b.addUpdateSourceFiles();
        awf.step.dependOn(b.getInstallStep());
        awf.addCopyFileToSource(exe.getEmittedAsm(), "main.asm");

        asm_step.dependOn(&awf.step);
        example_assembly_step.dependOn(asm_step);
    }
}
