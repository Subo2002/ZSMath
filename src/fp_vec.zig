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

    pub fn isFP(a: anytype) IsVector2FP {
        return @TypeOf(a).is_vector2FP;
    }

    pub fn ToType(is_vector2FP: IsVector2FP) type {
        const fp = is_vector2FP.fp_data;
        return Vector2FP(MakeFP(
            fp.int_bits,
            fp.frac_bits,
            fp.signedness,
        ));
    }

    pub fn asVector2FP(a: anytype) ToType(@TypeOf(a).is_vector2FP) {
        return a;
    }
};

pub fn Vector2FP(FPBase: type) type {
    //also makes sure the type is an FP
    const is_fp: IsFP = FPBase.is_fp;
    return struct {
        pub const is_vector2FP = IsVector2FP.init(is_fp);
        const Self = @This();
        pub const FP = FPBase;
        pub const FP2 = MakeFP(
            is_fp.int_bits * 2,
            is_fp.frac_bits * 2,
            is_fp.signedness,
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
            return .init(a.x.neg(), a.y.neg());
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

        pub inline fn mag2(a: Self) FP {
            const Vector2FP2 = Vector2FP(FP2);
            const b = Vector2FP2.implCast(a);
            return FP.cast(b.x.mult(b.x).add(b.y.mult(b.y)));
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
            const _mag2 = b.x.mult(b.x).add(b.y.mult(b.y));
            const _mag = _mag2.sqrt();
            return FP.cast(_mag);
        }

        pub const Vector2UnitFP = Vector2FP(FP.UnitFP);

        pub inline fn normalize(a: Self) Vector2UnitFP {
            //want to use intermediate FP with frac_bits incremented
            //by the number of int_bits, int_bits the same.
            //Then return an FP with the same size as the input FP,
            //but all but one of the int_bits are being used as frac bits now.
            //I for intermediate
            const IFP = MakeFP(
                is_fp.int_bits,
                is_fp.int_bits + is_fp.frac_bits,
                is_fp.signedness,
            );
            const Vector2IFP = Vector2FP(IFP);
            const b = Vector2IFP.implCast(a);
            return .cast(b.scale(IFP.one.div(b.mag())));
        }

        pub inline fn resize(a: Self, b: anytype) Vector2FP(IsFP.ToType(@TypeOf(b).is_fp)) {
            return .init(.multAny(a.x, b), .multAny(a.y, b));
        }

        pub inline fn scaleUnit(a: Self, b: FP.UnitFP) Self {
            return Self.init(a.x.multUnit(b), a.y.multUnit(b));
        }

        pub inline fn multUnit(a: Self, b: Vector2UnitFP) Self {
            return Self.init(a.x.multUnit(b.x), a.y.multUnit(b.y));
        }

        pub inline fn addAny(a: anytype, b: anytype) Self {
            const c = IsVector2FP.asVector2FP(a);
            const d = IsVector2FP.asVector2FP(b);
            return .init(.addAny(c.x, d.x), .addAny(c.y, d.y));
        }

        pub inline fn dot(a: Self, b: Self) FP {
            const Vector2FP2 = Vector2FP(FP2);
            const c = Vector2FP2.implCast(a);
            const d = Vector2FP2.implCast(b);
            return FP.cast(c.x.mult(d.x).add(c.y.mult(d.y)));
        }
    };
}

test "FPV normalize" {
    const FP = MakeFP(16, 1, .signed);
    const V2FP = Vector2FP(FP);
    const UnitV2FP = Vector2FP(FP.UnitFP);
    const a: V2FP = .initInt(200, 200);
    const a_hat: UnitV2FP = a.normalize();
    const a_hat_mag = a_hat.mag();
    const prec_sqrt = UnitV2FP.FP.prec.sqrt();
    try std.testing.expect(
        a_hat_mag.aprxEql(.fromInt(1), prec_sqrt),
    );
}

test "FPV round" {
    const V2FP = Vector2FP(MakeFP(16, 16, .signed));
    const a: V2FP = .initFloat(0.5, -0.4);
    try std.testing.expect(a.round().eql(.init(1, 0)));
}

test "FPV mag" {
    const V2FP = Vector2FP(MakeFP(16, 16, .signed));
    const a: V2FP = .initFloat(400, 300);
    const mag_a = a.mag();
    try std.testing.expect(mag_a.eql(.fromInt(500)));
}

test "FPV dot" {
    const V2FP = Vector2FP(MakeFP(16, 16, .signed));
    const a: V2FP = .initInt(1, 0);
    const b: V2FP = .initInt(1, 1);
    try std.testing.expect(a.dot(b).eql(.fromInt(1)));
}

test "FP unitScale" {
    const V2FP = Vector2FP(MakeFP(16, 16, .signed));
    const a: V2FP = .initInt(1, 1);
    const b = a.scaleUnit(.fromFloat(0.1));
    try std.testing.expect(b.x.aprxEql(.fromFloat(0.1), V2FP.FP.prec));
}

test "FP rescale" {
    const FP = MakeFP(16, 16, .signed);
    const V2FP = Vector2FP(FP);
    const a: V2FP.Vector2UnitFP = .initInt(1, 1);
    const b = a.resize(FP.fromFloat(10));
    try std.testing.expect(b.x.aprxEql(FP.fromFloat(10), FP.prec));
}

test "FP addAny" {
    const SmallFP = MakeFP(1, 15, .signed);
    const BigFP = MakeFP(16, 0, .signed);
    const FP = MakeFP(16, 16, .signed);
    const a: Vector2FP(SmallFP) = .initFloat(0.01, 0.01);
    const b: Vector2FP(BigFP) = .initInt(100, 100);
    const a_plus_b: Vector2FP(FP) = .addAny(a, b);
    try std.testing.expect(a_plus_b.x.aprxEql(FP.fromFloat(100.01), FP.prec));
}
