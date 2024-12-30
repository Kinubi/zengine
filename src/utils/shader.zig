const std = @import("std");
const gl = @import("gl");

pub const Shader = struct {
    sources: []const []const u8,

    pub fn new(source: [*]const u8) Shader {
        return Shader{
            .source = source,
        };
    }

    pub fn compile(self: *Shader) !void {
        // Compilation logic for the shader
    }
};

pub const Shaders = struct {
    var shaders: []Shader = undefined;
    const allocator = std.heap.page_allocator;
    const shaderProgram: c_uint = undefined;

    pub fn new(shaderSource: [*]const [*]const u8, shaderType: c_uint) Shaders {
        return Shaders{
            for (shaderSource) |source| {
                .shaders = append(.shaders, Shader.new(source));
            },
        };
    }
};
