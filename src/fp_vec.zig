const MakeFP = @import("fixed_point.zig").FP;
const FP = MakeFP(16, 16);
const Vectors = @import("vector.zig");
const Vector2I = Vectors.Vector2I;
const Vector2 = Vectors.Vector2;
const std = @import("std");

pub const Vector2FP = struct {
    x: FP,
    y: FP,

    pub const zero: Vector2FP = .{ .x = .zero, .y = .zero };

    pub inline fn init(x: FP, y: FP) Vector2FP {
        return .{ .x = x, .y = y };
    }

    pub inline fn initFloat(x: f32, y: f32) Vector2FP {
        return .init(.fromFloat(x), .fromFloat(y));
    }

    pub inline fn initInt(x: i32, y: i32) Vector2FP {
        return .init(.fromInt(x), .fromInt(y));
    }

    pub inline fn fromInt(a: Vector2I) Vector2FP {
        return .init(.fromInt(a.x), .fromInt(a.y));
    }

    pub inline fn add(a: Vector2FP, b: Vector2FP) Vector2FP {
        return .{ .x = a.x.add(b.x), .y = a.y.add(b.y) };
    }

    pub inline fn sub(a: Vector2FP, b: Vector2FP) Vector2FP {
        return .{ .x = a.x.sub(b.x), .y = a.y.sub(b.y) };
    }

    pub inline fn mult(a: Vector2FP, b: Vector2FP) Vector2FP {
        return .{ .x = a.x.mult(b.x), .y = a.y.mult(b.y) };
    }

    pub inline fn div(a: Vector2FP, b: Vector2FP) Vector2FP {
        return .{ .x = a.x.div(b.x), .y = a.y.div(b.y) };
    }

    pub inline fn scale(a: Vector2FP, c: FP) Vector2FP {
        return .{ .x = a.x.mult(c), .y = a.y.mult(c) };
    }

    pub inline fn round(a: Vector2FP) Vector2I {
        var b: Vector2I = .init(a.x.toInt(), a.y.toInt());
        const sign: Vector2I = .init(
            if (a.x.nonNeg()) 1 else -1,
            if (a.y.nonNeg()) 1 else -1,
        );
        b = b.mult(sign);
        const diff: Vector2FP = a.mult(.fromInt(sign)).sub(.fromInt(b));
        const half = FP.fromFrac(1, 2);
        if (diff.x.geq(half)) {
            b.x += 1;
        }
        if (diff.y.geq(half)) {
            b.y += 1;
        }
        return b.mult(sign);
    }

    pub inline fn toFloat(a: Vector2FP) Vector2 {
        return .{ .x = a.x.toFloat(), .y = a.y.toFloat() };
    }

    pub inline fn eql(a: Vector2FP, b: Vector2FP) bool {
        return a.x.eql(b.x) and a.y.eql(b.y);
    }

    pub inline fn mag2(a: Vector2FP) FP {
        return a.x.mult(a.x).add(a.y.mult(a.y));
    }

    pub inline fn mag(a: Vector2FP) FP {
        const FP32_32: type = MakeFP(32, 32);
        const x = FP32_32.implCast(a.x);
        const y = FP32_32.implCast(a.y);
        const y_2 = y.mult(y);
        const x_2 = x.mult(x);

        const magnitude_squared: FP32_32 = x_2.add(y_2);
        return FP.cast(magnitude_squared.sqrt());
    }

    pub inline fn normalize(a: Vector2FP) Vector2FP {
        return a.scale(FP.one.div(a.mag()));
    }
};

test "FPV round" {
    const a: Vector2FP = .initFloat(0.5, -0.4);
    try std.testing.expect(a.round().eql(.init(1, 0)));
}

test "FPV mag" {
    const a: Vector2FP = .initFloat(400, 300);
    const mag_a = a.mag();
    try std.testing.expect(mag_a.eql(.fromInt(500)));
}
