const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

// Procedure table that will hold OpenGL functions loaded at runtime.
var gl_procs: gl.ProcTable = undefined;
pub fn main() !void {
    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    // Create our window
    const window = glfw.Window.create(1280, 720, "Hello, zengine!", null, null, .{}) orelse {
        std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();
    glfw.makeContextCurrent(window);
    defer glfw.makeContextCurrent(null);

    if (!gl_procs.init(glfw.getProcAddress)) return error.GlInitFailed;

    gl.makeProcTableCurrent(&gl_procs);
    defer gl.makeProcTableCurrent(null);

    main_loop: while (true) {
        glfw.waitEvents();
        if (window.shouldClose()) break :main_loop;

        // This example draws using only scissor boxes and clearing. No actual shaders!
        gl.ClearColor(0.5, 0.1, 0.1, 1);
        gl.Clear(gl.COLOR_BUFFER_BIT);
        window.swapBuffers();
    }
}
