const std = @import("std");
const gl = @import("gl");

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
};
