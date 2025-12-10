const std = @import("std");
const assert = std.debug.assert;

//using 3 bytes for int part
//using 1 byte for fractional part
pub const FP = packed struct {
    back: i32,

    pub const frac_bits = 16;
    pub const frac_scale = 1 << frac_bits;
    pub const prec: FP = FP{ .back = 2 }; // = 2 / frac_scale

    pub const zero: FP = .{
        .back = 0,
    };

    pub fn fromInt(i: i32) FP {
        return FP{
            .back = i << frac_bits,
        };
    }

    pub fn toInt(f: FP) i32 {
        return @divTrunc(f.back, frac_scale);
    }

    pub fn getFrac(f: FP) i32 {
        return f.back - (@divTrunc(f.back, frac_scale) * frac_scale);
    }

    pub fn fromFloat(f: f32) FP {
        //const int: i32 = @intFromFloat(f);
        //const frac: i32 = @intFromFloat((f - @as(f32, @floatFromInt(int))) * frac_scale);
        //std.debug.print("int: {}, frac: {}", .{ int, frac });
        //return FP{
        //    .back = (int << frac_bits) + frac,
        //};
        return FP{
            .back = @intFromFloat(f * frac_scale),
        };
    }

    pub fn toFloat(f: FP) f32 {
        const int: f32 = @floatCast(f.back >> frac_bits);
        return int + (@as(f32, @floatCast(f.back - int)) >> frac_bits);
    }

    pub fn add(a: FP, b: FP) FP {
        return FP{
            .back = a.back + b.back,
        };
    }

    pub fn sub(a: FP, b: FP) FP {
        return FP{
            .back = a.back - b.back,
        };
    }

    pub fn mult(a: FP, b: FP) FP {
        return FP{
            .back = @intCast(@divTrunc(@as(i64, @intCast(a.back)) * @as(i64, @intCast(b.back)), frac_scale)),
        };
    }

    pub fn div(a: FP, b: FP) FP {
        assert(b.back != 0);
        return FP{
            .back = @intCast(@divTrunc(@as(i64, @intCast(a.back)) * frac_scale, b.back)),
        };
    }

    pub fn eql(a: FP, b: FP) bool {
        const e = a.sub(b).back;
        const abs_e = if (e >= 0) e else -e;
        return abs_e < FP.prec.back;
    }
};

const expect = std.testing.expect;

const float_test_values = [_]f32{
    1.0,
    2.0,
    -0.3,
    10000.34,
};

test "FP add" {
    const a: FP = FP.fromInt(1).add(FP.fromInt(1).div(.fromInt(5)));
    const b: FP = FP.fromInt(-3).div(.fromInt(10));
    const c: FP = FP.fromInt(9).div(.fromInt(10));
    const val = a.add(b);
    try expect(val.eql(c));
}

test "FP div" {}
