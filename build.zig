const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addLibrary(.{
        .name = "z",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    lib.root_module.addIncludePath(b.path("upstream"));

    lib.installHeadersDirectory(b.path("upstream"), "", .{
        .exclude_extensions = &.{ ".c", ".in", ".txt" },
    });

    var flags_list = std.ArrayListUnmanaged([]const u8).empty;
    defer flags_list.deinit(b.allocator);
    try flags_list.appendSlice(b.allocator, &.{
        "-DHAVE_SYS_TYPES_H",
        "-DHAVE_STDINT_H",
        "-DHAVE_STDDEF_H",
        "-DZ_HAVE_UNISTD_H",
    });
    if (target.result.os.tag != .windows) {
        // Hide symbols so a process that also dlopens a system zlib
        // (transitively via GTK / libpng / etc.) does not mix copies.
        try flags_list.append(b.allocator, "-fvisibility=hidden");
    }

    lib.root_module.addCSourceFiles(.{
        .root = b.path("upstream"),
        .files = srcs_relative,
        .flags = flags_list.items,
    });

    b.installArtifact(lib);
}

const srcs_relative = &.{
    "adler32.c",
    "compress.c",
    "crc32.c",
    "deflate.c",
    "gzclose.c",
    "gzlib.c",
    "gzread.c",
    "gzwrite.c",
    "inflate.c",
    "infback.c",
    "inftrees.c",
    "inffast.c",
    "trees.c",
    "uncompr.c",
    "zutil.c",
};
