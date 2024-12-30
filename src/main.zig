const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const Mesh = @import("renderer/mesh.zig").Mesh;
const Shader = @import("utils/shader.zig").Shader;
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
    const window = glfw.Window.create(1280, 720, "Hello, zengine!", null, null, .{
        .context_version_major = gl.info.version_major,
        .context_version_minor = gl.info.version_minor,
        .opengl_profile = .opengl_core_profile,
        .opengl_forward_compat = true,
    }) orelse {
        std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();
    glfw.makeContextCurrent(window);
    defer glfw.makeContextCurrent(null);

    if (!gl_procs.init(glfw.getProcAddress)) return error.GlInitFailed;

    gl.makeProcTableCurrent(&gl_procs);
    defer gl.makeProcTableCurrent(null);

    //Shaders
    const vertexShaderFP = "../../res/shaders/simple_shader.vert";
    const fragShaderFP = "../../res/shaders/simple_shader.frag";

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    const full_vs_path = std.fs.path.join(gpa.allocator(), &.{
        std.fs.selfExeDirPathAlloc(gpa.allocator()) catch unreachable,
        vertexShaderFP,
    }) catch unreachable;

    const full_fs_path = std.fs.path.join(gpa.allocator(), &.{
        std.fs.selfExeDirPathAlloc(gpa.allocator()) catch unreachable,
        fragShaderFP,
    }) catch unreachable;

    std.log.info("Full vs path: {s}, Full fs path: {s}", .{ full_vs_path, full_fs_path });

    const vs_file = std.fs.openFileAbsolute(full_vs_path, .{}) catch unreachable;
    const vertexShaderSource = vs_file.readToEndAllocOptions(gpa.allocator(), (10 * 1024), null, @alignOf(u8), 0) catch unreachable;

    const fs_file = std.fs.openFileAbsolute(full_fs_path, .{}) catch unreachable;
    const fragmentShaderSource = fs_file.readToEndAllocOptions(gpa.allocator(), (10 * 1024), null, @alignOf(u8), 0) catch unreachable;

    // Vertices
    const vertices = [_]f32{
        -0.5, -0.5, 0,
        0.5,  -0.5, 0,
        0.0,  0.5,  0,
    };

    const indices = [_]u32{
        0, 1, 2,
    };

    var mesh = Mesh.new(
        vertices[0..].ptr,
        indices[0..].ptr,
        vertices.len,
        indices.len,
    );

    mesh.genBuffers();
    mesh.bind();
    defer mesh.unbind();
    mesh.bufferData();
    defer mesh.delete();

    var shader = Shader{
        .vertSource = vertexShaderSource,
        .fragSource = fragmentShaderSource,
    };
    shader.compile();
    defer shader.deinit();

    main_loop: while (true) {
        glfw.waitEvents();
        if (window.shouldClose()) break :main_loop;

        gl.ClearColor(0.5, 0.1, 0.1, 1);
        gl.Clear(gl.COLOR_BUFFER_BIT);
        shader.bind();

        mesh.draw();
        window.swapBuffers();
    }
}
