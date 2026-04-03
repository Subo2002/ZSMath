const Vectors = @import("vector.zig");

pub const Vector2B = Vectors.Vector2B;
pub const Vector2I = Vectors.Vector2I;
pub const Vector2 = Vectors.Vector2;

const FPLib = @import("fixed_point.zig");
pub const FP = FPLib.FP;
const FPVecLib = @import("fp_vec.zig");
pub const Vector2FP = FPVecLib.Vector2FP;

const std = @import("std");
const FP16_16 = FP(16, 16);
test "Fp fromInt" {
    const a = FP16_16.fromInt(1);
    try std.testing.expectApproxEqRel(a.toFloat(), 1, @sqrt(2.0 / 65536.0));
}

test "FPVec" {
    const a = Vector2FP(FP(16, 16)).initInt(1, 1);
    _ = a;
}
