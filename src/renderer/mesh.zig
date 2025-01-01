const std = @import("std");
const gl = @import("gl");
const Shader = @import("shader.zig");
const math = @import("mach").math;

const v2zero = math.vec2(0, 0);
const v3zero = math.vec3(0, 0, 0);
const v4zero = math.vec4(0, 0, 0, 0);

pub const Vertex = extern struct {
    position: math.Vec3 = v3zero,
    uv: math.Vec2 = v2zero,
    normal: math.Vec3 = v3zero,
    color: math.Vec4 = v4zero,

    fn addAttributes() void {
        // logOffset("position");
        // logOffset("uv");
        // logOffset("normal");
        // logOffset("color");

        //const fs = @sizeOf(f32);
        Mesh.addElement(0, false, 3, 0); // position
        Mesh.addElement(1, false, 2, @offsetOf(Vertex, "uv")); // uvs
        Mesh.addElement(2, false, 3, @offsetOf(Vertex, "normal")); // normals
        Mesh.addElement(3, false, 4, @offsetOf(Vertex, "color")); // colors
    }

    fn logOffset(comptime name: []const u8) void {
        std.log.info("offset of {s}: {}", .{ name, @offsetOf(Vertex, name) });
    }
};

pub const Mesh = struct {
    vertices: std.ArrayList(Vertex),
    indices: std.ArrayList(u32),

    vao: c_uint = undefined,
    vbo: c_uint = undefined,
    ibo: c_uint = undefined,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Mesh {
        return .{
            .vertices = std.ArrayList(Vertex).init(allocator),
            .indices = std.ArrayList(u32).init(allocator),
        };
    }

    fn addElement(attributeId: u32, normalize: bool, elementCount: u32, elementPosition: u32) void {
        const norm: u8 = if (normalize) gl.TRUE else gl.FALSE;

        gl.VertexAttribPointer(attributeId, @intCast(elementCount), gl.FLOAT, norm, @sizeOf(Vertex), elementPosition);
        gl.EnableVertexAttribArray(attributeId);

        //try Shader.glLogError();
    }

    pub fn create(self: *Self) !void {
        // VAO, VBO, IBO

        gl.GenVertexArrays(1, @ptrCast(&self.vao));

        gl.GenBuffers(1, @ptrCast(&self.vbo));

        gl.GenBuffers(1, @ptrCast(&self.ibo));

        gl.BindVertexArray(self.vao);

        gl.BindBuffer(gl.ARRAY_BUFFER, self.vbo);

        gl.BufferData(gl.ARRAY_BUFFER, @intCast(self.vertices.items.len * @sizeOf(Vertex)), self.vertices.items[0..].ptr, gl.STATIC_DRAW);

        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.ibo);
        gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, @intCast(self.indices.items.len * @sizeOf(u32)), self.indices.items[0..].ptr, gl.STATIC_DRAW);

        Vertex.addAttributes();
        //try Shader.glLogError();
    }

    pub fn draw(self: Self) void {
        gl.BindVertexArray(self.vao);
        gl.DrawElements(gl.TRIANGLES, @intCast(self.indices.items.len), gl.UNSIGNED_INT, 0);
    }

    pub fn deinit(self: Self) void {
        gl.DeleteVertexArrays(1, @ptrCast(@constCast(&self.vao)));
        gl.DeleteBuffers(1, @ptrCast(@constCast(&self.vbo)));
        gl.DeleteBuffers(1, @ptrCast(@constCast(&self.ibo)));
        gl.BindBuffer(gl.ARRAY_BUFFER, 0);
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
        gl.BindVertexArray(0);

        self.indices.deinit();
        self.vertices.deinit();
    }
};
