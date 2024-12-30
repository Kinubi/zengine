const std = @import("std");
const gl = @import("gl");

pub const Mesh = struct {
    vertices: [*]const f32 = undefined,
    vertex_count: i32 = undefined,
    index_count: i32 = undefined,
    indices: [*]const u32 = undefined,
    vao: c_uint = undefined,
    vbo: c_uint = undefined,
    ibo: c_uint = undefined,

    pub fn new(vertices: [*]const f32, indices: [*]const u32, vertex_count: i32, index_count: i32) Mesh {
        return Mesh{
            .vertices = vertices,
            .indices = indices,
            .vertex_count = vertex_count,
            .index_count = index_count,
        };
    }

    pub fn genBuffers(self: *@This()) void {
        gl.GenVertexArrays(1, @ptrCast(&self.vao));
        gl.GenBuffers(1, @ptrCast(&self.vbo));
        gl.GenBuffers(1, @ptrCast(&self.ibo));
    }

    pub fn bind(self: @This()) void {
        gl.BindVertexArray(self.vao);
        gl.BindBuffer(gl.ARRAY_BUFFER, self.vbo);
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.ibo);
    }

    pub fn unbind(self: @This()) void {
        _ = self;
        gl.BindVertexArray(0);
        gl.BindBuffer(gl.ARRAY_BUFFER, 0);
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
    }

    pub fn bufferData(self: @This()) void {
        gl.BufferData(gl.ARRAY_BUFFER, self.vertex_count * @sizeOf(f32), @ptrCast(self.vertices), gl.STATIC_DRAW);
        gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, self.index_count * @sizeOf(u32), @ptrCast(self.indices), gl.STATIC_DRAW);
        gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), 0);
        gl.EnableVertexAttribArray(0);
    }

    pub fn delete(self: @This()) void {
        gl.DeleteVertexArrays(1, @ptrCast(@constCast(&self.vao)));
        gl.DeleteBuffers(1, @ptrCast(@constCast(&self.vbo)));
        gl.DeleteBuffers(1, @ptrCast(@constCast(&self.ibo)));
    }

    pub fn draw(self: @This()) void {
        gl.BindVertexArray(self.vao);
        gl.DrawElements(gl.TRIANGLES, @as(c_int, self.index_count), gl.UNSIGNED_INT, 0);
    }
};
