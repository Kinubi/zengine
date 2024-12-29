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

    const vertices = [_]f32{
        -0.5, -0.5, 0,
        0.5,  -0.5, 0,
        0.0,  0.5,  0,
    };

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

    std.debug.print("full_vs_path: {s}\n", .{full_vs_path});

    const vs_file = std.fs.openFileAbsolute(full_vs_path, .{}) catch unreachable;
    const vertexShaderSource = vs_file.readToEndAllocOptions(gpa.allocator(), (10 * 1024), null, @alignOf(u8), 0) catch unreachable;

    const fs_file = std.fs.openFileAbsolute(full_fs_path, .{}) catch unreachable;
    const fragmentShaderSource = fs_file.readToEndAllocOptions(gpa.allocator(), (10 * 1024), null, @alignOf(u8), 0) catch unreachable;

    const vertexShader = gl.CreateShader(gl.VERTEX_SHADER);
    gl.ShaderSource(vertexShader, 1, &.{vertexShaderSource.ptr}, null);
    gl.CompileShader(vertexShader);
    var success: i32 = undefined;
    gl.GetShaderiv(vertexShader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        var infoLog: [512]u8 = undefined;
        gl.GetShaderInfoLog(vertexShader, 512, null, infoLog[0..]);
        std.log.err("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n{s}\n", .{infoLog});
    }
    defer gl.DeleteShader(vertexShader);

    const fragmentShader = gl.CreateShader(gl.FRAGMENT_SHADER);
    gl.ShaderSource(fragmentShader, 1, &.{fragmentShaderSource.ptr}, null);
    gl.CompileShader(fragmentShader);
    gl.GetShaderiv(fragmentShader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        var infoLog: [512]u8 = undefined;
        gl.GetShaderInfoLog(fragmentShader, 512, null, infoLog[0..]);
        std.log.err("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{s}\n", .{infoLog});
    }
    defer gl.DeleteShader(fragmentShader);

    const shader = gl.CreateProgram();
    gl.AttachShader(shader, vertexShader);
    gl.AttachShader(shader, fragmentShader);
    gl.LinkProgram(shader);
    defer gl.DeleteProgram(shader);

    var vao: u32 = undefined;
    gl.GenVertexArrays(1, @ptrCast(&vao));
    defer gl.DeleteVertexArrays(1, @ptrCast(&vao));

    gl.BindVertexArray(vao);
    defer gl.BindVertexArray(0);

    var vbo: u32 = undefined;
    gl.GenBuffers(1, @ptrCast(&vbo));
    defer gl.DeleteBuffers(1, @ptrCast(&vbo));

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
    defer gl.BindBuffer(gl.ARRAY_BUFFER, 0);

    gl.BufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), vertices[0..].ptr, gl.STATIC_DRAW);

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), 0);
    gl.EnableVertexAttribArray(0);

    main_loop: while (true) {
        glfw.waitEvents();
        if (window.shouldClose()) break :main_loop;

        gl.ClearColor(0.5, 0.1, 0.1, 1);
        gl.Clear(gl.COLOR_BUFFER_BIT);
        gl.UseProgram(shader);
        gl.BindVertexArray(vao);
        gl.DrawArrays(gl.TRIANGLES, 0, 3);
        window.swapBuffers();
    }
}
