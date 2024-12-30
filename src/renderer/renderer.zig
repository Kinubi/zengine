const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const Mesh = @import("mesh.zig").Mesh;
const Shader = @import("shader.zig").Shader;
const Camera = @import("camera.zig").Camera;
const math = @import("mach").math;

pub const Renderer = struct {
    window: ?glfw.Window = null,
    gl_procs: gl.ProcTable = undefined,
    mesh: Mesh = undefined,
    shader: Shader = undefined,
    camera: Camera = Camera{},
    var motion = math.vec3(0, 0, 0);

    fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
        std.log.err("glfw: {}: {s}\n", .{ error_code, description });
    }
    pub fn init(self: *@This()) !void {
        glfw.setErrorCallback(errorCallback);
        if (!glfw.init(.{})) {
            return error.GlfwInitFailed;
        }

        // Create our window
        self.window = glfw.Window.create(1280, 720, "Hello, zengine!", null, null, .{
            .context_version_major = gl.info.version_major,
            .context_version_minor = gl.info.version_minor,
            .opengl_profile = .opengl_core_profile,
            .opengl_forward_compat = true,
        }) orelse {
            return error.GlfwWindowCreationFailed;
        };

        glfw.makeContextCurrent(self.window);

        if (!self.gl_procs.init(glfw.getProcAddress)) {
            return error.GlInitFailed;
        }

        gl.makeProcTableCurrent(&self.gl_procs);

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

        // Vertices
        const vertices = [_]f32{
            0, 0, 0,
            1, 0, 0,
            0, 1, 0,
            1, 1, 0,
            0, 0, 1,
            1, 0, 1,
            0, 1, 1,
            1, 1, 1,
        };

        const indices = [_]u32{
            0, 1, 2,
            2, 3, 0,
            // right
            1, 5, 6,
            6, 2, 1,
            // back
            7, 6, 5,
            5, 4, 7,
            // left
            4, 0, 3,
            3, 7, 4,
            // bottom
            4, 5, 1,
            1, 0, 4,
            // top
            3, 2, 6,
            6, 7, 3,
        };

        self.mesh = Mesh.new(
            vertices[0..].ptr,
            indices[0..].ptr,
            vertices.len,
            indices.len,
        );

        self.mesh.genBuffers();
        self.mesh.bind();

        self.mesh.bufferData();

        self.shader = Shader{
            .vertSource = vertexShaderSource,
            .fragSource = fragShaderSource,
        };
        self.shader.compile();

        const mat = self.camera.projectionMatrix;
        std.debug.print("Projection matrix: {any}\n", .{mat});
    }

    pub fn deinit(self: *@This()) void {
        self.shader.deinit();
        self.mesh.delete();
        self.mesh.unbind();
        self.window.?.destroy();
        gl.makeProcTableCurrent(null);
        glfw.makeContextCurrent(null);
        glfw.terminate();
    }

    pub fn isRunning(self: @This()) bool {
        glfw.pollEvents();

        gl.ClearColor(0.5, 0.1, 0.1, 1);
        gl.Clear(gl.COLOR_BUFFER_BIT);
        motion.v[0] = @floatCast(@sin(glfw.getTime()));
        std.debug.print("Motion: {any}\n", .{motion});
        Shader.setVec3(0, motion);
        Shader.setMatrix(1, self.camera.projectionMatrix);
        self.shader.bind();

        self.mesh.draw();

        self.window.?.swapBuffers();
        return !self.window.?.shouldClose();
    }
};
