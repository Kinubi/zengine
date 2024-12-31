const std = @import("std");
const gl = @import("gl");
const math = @import("mach").math;

pub const Shader = struct {
    program: u32 = 0,
    vertSource: []const u8,
    fragSource: []const u8,
    const Self = @This();
    pub fn compile(self: *Self) void {
        const vertShader = gl.CreateShader(gl.VERTEX_SHADER);
        gl.ShaderSource(vertShader, 1, &.{self.vertSource.ptr}, null);
        gl.CompileShader(vertShader);
        const fragShader = gl.CreateShader(gl.FRAGMENT_SHADER);
        gl.ShaderSource(fragShader, 1, &.{self.fragSource.ptr}, null);
        gl.CompileShader(fragShader);
        self.program = gl.CreateProgram();
        gl.AttachShader(self.program, vertShader);
        gl.AttachShader(self.program, fragShader);
        gl.LinkProgram(self.program);
        gl.DeleteShader(vertShader);
        gl.DeleteShader(fragShader);
    }
    pub fn bind(self: Self) void {
        gl.UseProgram(self.program);
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
    }
};
