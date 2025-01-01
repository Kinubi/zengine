const std = @import("std");
const gl = @import("gl");
const math = @import("mach").math;

pub const Shader = struct {
    program: u32 = undefined,
    vertSource: []const u8,
    fragSource: []const u8,
    const Self = @This();

    const Error = error{
        InvalidUniformName,
        ShaderCompilationFailed,
        GLError,
    };

    fn logShaderError(shader: u32) !void {
        var isCompiled: i32 = 0;
        gl.GetShaderiv(shader, gl.COMPILE_STATUS, &isCompiled);

        if (isCompiled == gl.FALSE) {
            var maxLength: i32 = 0;
            gl.GetShaderiv(shader, gl.INFO_LOG_LENGTH, &maxLength);

            const errorLogSize: usize = 512;
            var errorLog = [1:0]u8{0} ** errorLogSize;
            gl.GetShaderInfoLog(shader, errorLogSize, &maxLength, &errorLog);

            gl.DeleteShader(shader);

            std.log.err("\nShader compilation failed:\n{s}", .{errorLog[0..@intCast(maxLength)]});

            return Shader.Error.ShaderCompilationFailed;
        }
    }

    fn logLinkError(program: u32) !void {
        var isCompiled: i32 = 0;
        gl.GetProgramiv(program, gl.LINK_STATUS, &isCompiled);
        std.debug.print("isCompiled: {d}\n", .{isCompiled});

        if (isCompiled == gl.FALSE) {
            var maxLength: i32 = 0;
            gl.GetProgramiv(program, gl.INFO_LOG_LENGTH, &maxLength);

            const errorLogSize: usize = 512;
            var errorLog = [1:0]u8{0} ** errorLogSize;
            gl.GetProgramInfoLog(program, errorLogSize, &maxLength, &errorLog);

            gl.DeleteProgram(program);

            std.log.err("\nShader compilation failed:\n{s}", .{errorLog[0..@intCast(maxLength)]});

            return Shader.Error.ShaderCompilationFailed;
        }
    }

    pub fn compile(self: *Self) !void {
        const vertShader = gl.CreateShader(gl.VERTEX_SHADER);
        gl.ShaderSource(vertShader, 1, &.{self.vertSource.ptr}, null);
        gl.CompileShader(vertShader);
        try logShaderError(vertShader);
        const fragShader = gl.CreateShader(gl.FRAGMENT_SHADER);
        gl.ShaderSource(fragShader, 1, &.{self.fragSource.ptr}, null);
        gl.CompileShader(fragShader);
        try logShaderError(fragShader);
        self.program = gl.CreateProgram();

        gl.AttachShader(self.program, vertShader);
        gl.AttachShader(self.program, fragShader);
        gl.LinkProgram(self.program);

        try logLinkError(self.program);
        gl.DeleteShader(vertShader);
        gl.DeleteShader(fragShader);

        try glLogError();
    }
    pub fn bind(self: Self) void {
        gl.UseProgram(self.program);
        try glLogError();
    }
    pub fn deinit(self: Self) void {
        gl.DeleteProgram(self.program);
    }

    pub fn setUniform(location: i32, value: anytype) void {
        comptime {
            const T = @TypeOf(value);
            if (T != i32 and
                T != f32 and
                T != math.Vec2 and
                T != math.Vec3 and
                T != math.Vec4 and
                T != math.Mat4x4)
            {
                @compileError("Uniform with type of " ++ @typeName(T) ++ " is not supported");
            }
        }

        switch (@TypeOf(value)) {
            inline i32 => gl.Uniform1i(location, value),
            inline f32 => gl.Uniform1f(location, value),
            inline math.Vec2 => gl.Uniform2fv(location, 1, &value.v[0]),
            inline math.Vec3 => gl.Uniform3fv(location, 1, &value.v[0]),
            inline math.Vec4 => gl.Uniform4fv(location, 1, &value.v[0]),
            inline math.Mat4x4 => gl.UniformMatrix4fv(location, 1, gl.FALSE, &value.v[0].v[0]),
            inline else => unreachable,
        }

        try glLogError();
    }

    pub fn setUniformByName(self: Self, name: [:0]const u8, value: anytype) void {
        const location = gl.GetUniformLocation(self.program, name);

        if (location < 0)
            std.debug.print("Error setting uniform: {any}\n", .{Error.InvalidUniformName});
        try glLogError();

        setUniform(location, value);
    }
};

pub fn glLogError() !void {
    var err = gl.GetError();
    std.debug.print("GL error: {d}\n", .{err});

    while (err != gl.NO_ERROR) {
        const errorString = switch (err) {
            gl.INVALID_ENUM => "INVALID_ENUM",
            gl.INVALID_VALUE => "INVALID_VALUE",
            gl.INVALID_OPERATION => "INVALID_OPERATION",
            gl.OUT_OF_MEMORY => "OUT_OF_MEMORY",
            gl.INVALID_FRAMEBUFFER_OPERATION => "INVALID_FRAMEBUFFER_OPERATION",
            else => "unknown error",
        };

        // GL_STACK_OVERFLOW and GL_STACK_UNDEFLOW don't exist??

        std.log.err("Found OpenGL error: {s}", .{errorString});

        err = gl.GetError();
    }
}
