const MakeFP = @import("fixed_point.zig").FP;
const IsFP = @import("fixed_point.zig").IsFP;
const Vectors = @import("vector.zig");
const Vector2I = Vectors.Vector2I;
const Vector2 = Vectors.Vector2;
const std = @import("std");
const assert = std.debug.assert;

pub const IsVector2FP = struct {
    fp_data: IsFP,

    pub fn init(fp_data: IsFP) IsVector2FP {
        return IsVector2FP{ .fp_data = fp_data };
    }

    pub fn ToType(is_vector2FP: IsVector2FP) type {
        const fp = is_vector2FP.fp_data;
        return Vector2FP(MakeFP(fp.int_bits, fp.frac_bits));
    }

    pub fn asVector2FP(a: anytype) ToType((@TypeOf(a).is_vector2FP)) {
        return a;
    }
};

pub fn Vector2FP(FP: type) type {
    //also makes sure the type is an FP
    const is_fp: IsFP = FP.is_fp;
    return struct {
        pub const is_vector2FP = IsVector2FP.init(is_fp);
        const Self = @This();
        pub const FP2 = MakeFP(
            is_fp.int_bits * 2,
            is_fp.frac_bits * 2,
        );

        x: FP,
        y: FP,

        pub const zero: Self = .{ .x = .zero, .y = .zero };

        pub inline fn init(x: FP, y: FP) Self {
            return .{ .x = x, .y = y };
        }

        pub inline fn initFloat(x: f32, y: f32) Self {
            return .init(.fromFloat(x), .fromFloat(y));
        }

        pub inline fn initInt(x: i32, y: i32) Self {
            return .init(.fromInt(x), .fromInt(y));
        }

        pub inline fn fromInt(a: Vector2I) Self {
            return .init(.fromInt(a.x), .fromInt(a.y));
        }

        pub inline fn neg(a: Self) Self {
            return Self(a.x.neg(), a.y.neg());
        }

        pub inline fn add(a: Self, b: Self) Self {
            return .{ .x = a.x.add(b.x), .y = a.y.add(b.y) };
        }

        pub inline fn sub(a: Self, b: Self) Self {
            return .{ .x = a.x.sub(b.x), .y = a.y.sub(b.y) };
        }

        pub inline fn mult(a: Self, b: Self) Self {
            return .{ .x = a.x.mult(b.x), .y = a.y.mult(b.y) };
        }

        pub inline fn div(a: Self, b: Self) Self {
            return .{ .x = a.x.div(b.x), .y = a.y.div(b.y) };
        }

        pub inline fn scale(a: Self, c: FP) Self {
            return .{ .x = a.x.mult(c), .y = a.y.mult(c) };
        }

        pub inline fn round(a: Self) Vector2I {
            var b: Vector2I = .init(a.x.toInt(), a.y.toInt());
            const sign: Vector2I = .init(
                if (a.x.nonNeg()) 1 else -1,
                if (a.y.nonNeg()) 1 else -1,
            );
            b = b.mult(sign);
            const diff: Self = a.mult(.fromInt(sign)).sub(.fromInt(b));
            const half = FP.fromFrac(1, 2);
            if (diff.x.geq(half)) {
                b.x += 1;
            }
            if (diff.y.geq(half)) {
                b.y += 1;
            }
            return b.mult(sign);
        }

        pub inline fn toFloat(a: Self) Vector2 {
            return .{ .x = a.x.toFloat(), .y = a.y.toFloat() };
        }

        pub inline fn eql(a: Self, b: Self) bool {
            return a.x.eql(b.x) and a.y.eql(b.y);
        }

        pub inline fn mag2(a: Self) FP2 {
            const Vector2FP2 = Vector2FP(FP2);
            const b = Vector2FP2.implCast(a);
            return b.x.mult(b.x).add(b.y.mult(b.y));
        }

        pub inline fn implCast(a: anytype) Self {
            const b = IsVector2FP.asVector2FP(a);
            return .init(FP.implCast(b.x), FP.implCast(b.y));
        }

        pub inline fn cast(a: anytype) Self {
            const b = IsVector2FP.asVector2FP(a);
            return .init(FP.cast(b.x), FP.cast(b.y));
        }

        pub inline fn mag(a: Self) FP {
            const Vector2FP2 = Vector2FP(FP2);
            const b = Vector2FP2.implCast(a);
            return FP.cast(b.x.mult(b.x).add(b.y.mult(b.y)).sqrt());
        }

        pub inline fn normalize(a: Self) Self {
            return a.scale(FP.one.div(a.mag()));
        }

        pub inline fn dot(a: Self, b: Self) FP2 {
            const Vector2FP2 = Vector2FP(FP2);
            const c = Vector2FP2.implCast(a);
            const d = Vector2FP2.implCast(b);
            return c.x.mult(d.x).add(c.y.mult(d.y));
        }
    };
}

test "FPV round" {
    const V2FP = Vector2FP(MakeFP(16, 16));
    const a: V2FP = .initFloat(0.5, -0.4);
    try std.testing.expect(a.round().eql(.init(1, 0)));
}

test "FPV mag" {
    const V2FP = Vector2FP(MakeFP(16, 16));
    const a: V2FP = .initFloat(400, 300);
    const mag_a = a.mag();
    try std.testing.expect(mag_a.eql(.fromInt(500)));
}

test "FPV dot" {
    const V2FP = Vector2FP(MakeFP(16, 16));
    const a: V2FP = .initInt(1, 0);
    const b: V2FP = .initInt(1, 1);
    try std.testing.expect(a.dot(b).eql(.fromInt(1)));
}
