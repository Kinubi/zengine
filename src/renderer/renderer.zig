const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const Mesh = @import("renderer/mesh.zig").Mesh;
const Shader = @import("utils/shader.zig").Shader;

pub renderer = struct {
    window: glfw.Window,
    gl_procs: gl.ProcTable,
    mesh: Mesh,
    shader: Shader,
    pub fn init() !void {
        glfw.setErrorCallback(errorCallback);
        if (!glfw.init(.{})) {
            return error.GlfwInitFailed;
        }
        defer glfw.terminate();

        // Create our window
        const window = glfw.Window.create(1280, 720, "Hello, zengine!", null, null, .{
            .context_version_major = gl.info.version_major,
            .context_version_minor = gl.info.version_minor,
            .opengl_profile = .opengl_core_profile,
            .opengl_forward_compat = true,
        }) orelse {
            return error.GlfwWindowCreationFailed;
        };
        defer window.destroy();
        glfw.makeContextCurrent(window);
        defer glfw.makeContextCurrent(null);

        if (!gl_procs.init(glfw.getProcAddress)) {
            return error.GlInitFailed;
        }

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
        const fragShaderSource = fs_file.readToEndAllocOptions(gpa.allocator(), (10 * 1024), null, @alignOf(u8), 0) catch unreachable;
};