const std = @import("std");
const Renderer = @import("renderer/renderer.zig").Renderer;

pub fn main() !void {
    var renderer = Renderer{};
    try renderer.init();
    defer renderer.deinit();

    while (renderer.isRunning()) {}
}
