const math = @import("mach").math;

const std = @import("std");

pub const Camera = struct {
    projectionMatrix: math.Mat4x4 = math.Mat4x4.ident,
};
