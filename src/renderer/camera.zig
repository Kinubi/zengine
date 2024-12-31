const math = @import("mach").math;
const Renderer = @import("renderer.zig").Renderer;

const std = @import("std");

pub const Camera = struct {
    projectionMatrix: math.Mat4x4 = math.Mat4x4.ident,
    viewMatrix: math.Mat4x4 = math.Mat4x4.ident,

    nearPlane: f32 = -1,
    farPlane: f32 = 1000,
    fov: f32 = 75,
    aspectRatio: f32 = 16.0 / 9.0,

    renderer: *Renderer = undefined,

    pub fn perspective(
        /// The field of view angle in the y direction, in radians.
        fovy: f32,
        /// The aspect ratio of the viewport's width to its height.
        aspect: f32,
        /// The depth (z coordinate) of the near clipping plane.
        near: f32,
        /// The depth (z coordinate) of the far clipping plane.
        far: f32,
    ) math.Mat4x4 {
        const tanHalfFovy: f32 = @tan(fovy / 2.0);

        const r00: f32 = 1.0 / (aspect * tanHalfFovy);
        const r11: f32 = 1.0 / (tanHalfFovy);
        const r22: f32 = far / (near - far);
        const r23: f32 = -1;
        const r32: f32 = -(far * near) / (far - near);

        return math.Mat4x4.init(
            &math.Vec4.init(r00, 0, 0, 0),
            &math.Vec4.init(0, r11, 0, 0),
            &math.Vec4.init(0, 0, r22, r23),
            &math.Vec4.init(0, 0, r32, 0),
        );
    }

    pub fn updateProjectionMatrix(self: *Camera) void {
        const size = self.renderer.window.?.getSize();
        self.aspectRatio = @as(f32, @floatFromInt(size.width)) / @as(f32, @floatFromInt(size.height));

        self.projectionMatrix = perspective(
            math.degreesToRadians(self.fov),
            self.aspectRatio,
            self.nearPlane,
            self.farPlane,
        );
    }
};
