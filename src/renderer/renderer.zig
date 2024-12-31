const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const Mesh = @import("mesh.zig").Mesh;
const Shader = @import("shader.zig").Shader;
const Camera = @import("camera.zig").Camera;
const math = @import("mach").math;

pub const WindowProps = struct {
    width: u32 = 800,
    height: u32 = 600,
    fullscreen: bool = true,
    title: [:0]const u8 = "Hello Zengine!",
    vsync: bool = true,
};

pub const Renderer = struct {
    window: ?glfw.Window = null,
    gl_procs: gl.ProcTable = undefined,
    mesh: Mesh = undefined,
    shader: Shader = undefined,
    var camera: Camera = .{};

    var motion = math.vec3(0, 0, 0);
    var camOffset = math.vec3(0, 0, 0);

    fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
        std.log.err("glfw: {}: {s}\n", .{ error_code, description });
    }
    pub fn init(self: *@This(), windowProps: WindowProps) !void {
        glfw.setErrorCallback(errorCallback);
        if (!glfw.init(.{})) {
            return error.GlfwInitFailed;
        }

        var monitor = glfw.Monitor.getPrimary().?;
        const mode = monitor.getVideoMode().?;

        const width = if (windowProps.fullscreen) mode.getWidth() else windowProps.width;
        const height = if (windowProps.fullscreen) mode.getHeight() else windowProps.height;

        // Create our window
        self.window = glfw.Window.create(width, height, windowProps.title, if (windowProps.fullscreen) monitor else null, null, .{
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

        glfw.swapInterval(if (windowProps.vsync) 1 else 0);

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

        camera.renderer = self;
        //camera.updateProjectionMatrix();
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
        const speed = 0.001;

        if (self.keyPressed(.w)) {
            camOffset.v[2] -= speed;
        } else if (self.keyPressed(.s)) {
            camOffset.v[2] += speed;
        }

        if (self.keyPressed(.a)) {
            camOffset.v[0] += speed;
        } else if (self.keyPressed(.d)) {
            camOffset.v[0] -= speed;
        }

        if (self.keyPressed(.c)) {
            camera.nearPlane += 0.01;
            camera.updateProjectionMatrix();
        } else if (self.keyPressed(.x)) {
            camera.nearPlane -= 0.01;
            camera.updateProjectionMatrix();
        }

        const camOffsetMatrix = math.Mat4x4.translate(camOffset);
        camera.viewMatrix = math.Mat4x4.ident.mul(&camOffsetMatrix);

        //Shader.setMatrix(0, engine.camera.projectionMatrix);

        motion.v[0] = @floatCast(@sin(glfw.getTime()));
        motion.v[1] = @floatCast(@cos(glfw.getTime()));
        glfw.pollEvents();

        gl.ClearColor(0.5, 0.1, 0.1, 1);
        gl.Clear(gl.COLOR_BUFFER_BIT);
        motion.v[0] = @floatCast(@sin(glfw.getTime()));
        std.debug.print("View matrix: {any}\n", .{camera.viewMatrix});
        std.debug.print("Projection matrix: {any}\n", .{camera.projectionMatrix});
        Shader.setUniform(0, motion);
        Shader.setUniform(1, camera.projectionMatrix);
        //Shader.setUniform(2, camera.viewMatrix);
        self.shader.bind();

        self.mesh.draw();

        self.window.?.swapBuffers();
        return !self.window.?.shouldClose();
    }

    pub fn keyPressed(self: @This(), key: glfw.Key) bool {
        return self.window.?.getKey(key) == glfw.Action.press;
    }
};
