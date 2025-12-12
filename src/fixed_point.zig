const std = @import("std");
const assert = std.debug.assert;

//using 2 bytes for int part
//using 2 byte for fractional part
pub const FP = packed struct {
    back: i32,

    pub const frac_bits = 16;
    pub const frac_scale = 1 << frac_bits;
    pub const prec: FP = FP{ .back = 2 }; // = 2 / frac_scale

    pub const zero: FP = .fromInt(0);
    pub const one: FP = .fromInt(1);
    pub const pi: FP = .fromFrac(355, 113);
    pub const min_one: FP = .fromInt(-1);
    pub const pi_2: FP = pi.div(.fromInt(2));
    pub const min_pi_2: FP = pi_2.mult(min_one);
    pub const pi_4: FP = pi_2.div(.fromInt(2));
    pub const min_pi: FP = .neg(pi);

    pub fn fromFormat(comptime a: []const u8) !FP {
        var start: u1 = 0;
        var sign: i2 = 1;
        if (a[0] == '-') {
            sign = -1;
            start = 1;
        }

        const int_end = for (a[start..], start..) |c, index| {
            if (c != '.') continue;
            break index;
        } else a.len;

        const int = try fromFormat_intPart(a[start..int_end]);
        const frac_len: i32 = @intCast(a.len - int_end - 1);
        const frac_size = std.math.pow(i32, 10, frac_len);
        const frac = try fromFormat_intPart(a[(int_end + 1)..]);
        const _frac = FP.fromFrac(frac, frac_size);
        return FP.fromInt(sign).mult(FP.fromInt(int).add(_frac));
    }

    fn fromFormat_intPart(a: []const u8) !u16 {
        var sum: u16 = 0;
        for (a) |c| {
            const inc: u16 = switch (c) {
                '0' => 0,
                '1' => 1,
                '2' => 2,
                '3' => 3,
                '4' => 4,
                '5' => 5,
                '6' => 6,
                '7' => 7,
                '8' => 8,
                '9' => 9,
                else => unreachable,
            };
            sum *= 10;
            sum += inc;
        }
        return sum;
    }

    pub inline fn fromInt(i: i32) FP {
        return FP{
            .back = i * frac_scale,
        };
    }

    pub inline fn fromFrac(a: i32, b: i32) FP {
        return FP.fromInt(a).div(.fromInt(b));
    }

    pub inline fn toInt(f: FP) i32 {
        return @divTrunc(f.back, frac_scale);
    }

    pub inline fn getFrac(f: FP) f32 {
        const frac_int = f.back - (@divTrunc(f.back, frac_scale) * frac_scale);
        return @as(f32, @floatFromInt(frac_int)) / @as(f32, @floatFromInt(FP.frac_scale));
    }

    pub inline fn fromFloat(f: f32) FP {
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

    pub inline fn toFloat(f: FP) f32 {
        const int = f.back >> frac_bits;
        const frac_part = f.back - (int << frac_bits);
        const frac: f32 = @as(f32, @floatFromInt(frac_part));
        return @as(f32, @floatFromInt(int)) + (frac / frac_scale);
    }

    pub inline fn add(a: FP, b: FP) FP {
        return FP{
            .back = a.back + b.back,
        };
    }

    pub inline fn addEql(a: *FP, b: FP) void {
        a = a.add(b);
    }

    pub inline fn sub(a: FP, b: FP) FP {
        return FP{
            .back = a.back - b.back,
        };
    }

    pub inline fn mult(a: FP, b: FP) FP {
        return FP{
            .back = @intCast(@divTrunc(@as(i64, @intCast(a.back)) * @as(i64, @intCast(b.back)), frac_scale)),
        };
    }

    pub inline fn div(a: FP, b: FP) FP {
        assert(b.back != 0);
        return FP{
            .back = @intCast(@divTrunc(@as(i64, @intCast(a.back)) * frac_scale, b.back)),
        };
    }

    pub inline fn sqrt(a: FP) FP {
        assert(a.back >= 0);
        return FP{
            .back = @intCast(std.math.sqrt(@as(u64, @intCast(a.back)) * frac_scale)),
        };
    }

    pub inline fn neg(a: FP) FP {
        return FP{
            .back = -a.back,
        };
    }

    //think of radians as -pi to pi as that's where the taylor approx. is good
    pub inline fn toPrincipleRadianRange(radian: FP) FP {
        const neg_pi = FP.pi.mult(.fromInt(-1));
        const pi2 = FP.pi.mult(.fromInt(2));
        var b = @mod(radian.back, pi2.back);
        if (b < neg_pi.back) {
            b += pi2.back;
        } else if (b > pi.back) {
            b -= pi2.back;
        }
        return FP{ .back = b };
    }

    pub fn sin(a: FP) FP {
        //sooo nice, range restriction is so good
        var x = a.toPrincipleRadianRange();
        if (x.greaterThan(.pi_2)) {
            x = FP.pi.sub(x);
        } else if (x.lessThan(FP.min_pi_2)) {
            x = FP.min_pi.sub(x);
        }
        const x_2 = x.mult(x);
        const x_3 = x.mult(x_2).div(.fromInt(-6));
        const x_5 = x_3.mult(x_2).div(.fromInt(-20));
        return x.add(x_3).add(x_5);
    }

    pub fn cos(a: FP) FP {
        const x = a.toPrincipleRadianRange();
        if (x.greaterThan(.pi_2)) {
            return FP.pi.sub(x).cosNice().neg();
        } else if (x.lessThan(.min_pi_2)) {
            return FP.min_pi.sub(x).cosNice().neg();
        } else {
            return x.cosNice();
        }
    }

    inline fn cosNice(x: FP) FP {
        assert(x.leq(.pi_2) and x.geq(.min_pi_2));
        const s = x.mult(x);
        const x_2 = s.div(.fromInt(-2));
        const x_4 = x_2.mult(s).div(.fromInt(-12));
        const x_6 = x_4.mult(s).div(.fromInt(-30));
        //const x_8 = x_6.mult(s).div(.fromInt(-56));
        return FP.one.add(x_2).add(x_4).add(x_6);
    }

    pub fn atan(a: FP) FP {
        if (a.greaterThan(.one)) {
            return pi_2.sub(atanSmallBetter(FP.one.div(a)));
        }
        if (a.lessThan(.min_one)) {
            return min_pi_2.sub(atanSmallBetter(FP.one.div(a)));
        }
        return atanSmallBetter(a);
    }

    //inline fn atanSmall(a: FP) FP {
    //    assert(a.abs().leq(1));
    //
    //    const a2: FP = a.mult(a);
    //
    //    const p = FP.fromFormat("0.280872") catch @compileError("invalid FP format");
    //    const q = FP.fromtFormat("1.05876") catch @compileError("invalid FP format");
    //
    //    const num: FP = FP.one.add(p.mult(a2));
    //    const den: FP = FP.one.add(q.mult(a2));
    //
    //    return a.mult(num.div(den));
    //}

    inline fn atanSmallBetter(a: FP) FP {
        assert(a.abs().leq(.one));

        const b: FP = a.abs().sub(.one);

        //magic function nonesense
        const p = FP.fromFormat("0.2447") catch @compileError("invalid FP format");
        const q = FP.fromFormat("0.0663") catch @compileError("invalid FP format");
        const c: FP = p.add(q.mult(a.abs()));

        return a.mult(.pi_4).sub(a.mult(b).mult(c));
    }

    pub inline fn aprxEql(a: FP, b: FP, comptime precision: FP) bool {
        const e = a.sub(b).back;
        const abs_e = if (e >= 0) e else -e;
        return abs_e < precision.back;
    }

    pub inline fn eql(a: FP, b: FP) bool {
        return a.back == b.back;
    }

    pub inline fn lessThan(a: FP, b: FP) bool {
        return a.back < b.back;
    }

    pub inline fn greaterThan(a: FP, b: FP) bool {
        return a.back > b.back;
    }

    pub inline fn leq(a: FP, b: FP) bool {
        return a.back <= b.back;
    }

    pub inline fn geq(a: FP, b: FP) bool {
        return a.back >= b.back;
    }

    pub inline fn abs(a: FP) FP {
        return if (a.geq(.zero)) a else a.neg();
    }
};

const Vectors = @import("vector.zig");
const Vector2I = Vectors.Vector2I;
const Vector2 = Vectors.Vector2;

pub const Vector2FP = struct {
    x: FP,
    y: FP,

    pub const zero: Vector2FP = .{ .x = .zero, .y = .zero };

    pub inline fn init(x: FP, y: FP) Vector2FP {
        return .{ .x = x, .y = y };
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
            if (b.x.geq(.zero)) 1 else -1,
            if (b.y.geq(.zero)) 1 else -1,
        );
        b = b.mult(sign);
        const diff: Vector2FP = a.mult(.fromInt(sign)).sub(.fromInt(b));
        const half = .fromFromFrac(1, 2);
        if (diff.x.geq(half)) {
            b.x += 1;
        }
        if (diff.y.geq(half)) {
            b.y += 1;
        }
        return b;
    }

    pub inline fn toFloat(a: Vector2FP) Vector2 {
        return .{ .x = a.x.toFloat(), .y = a.y.toFloat() };
    }

    pub inline fn eql(a: Vector2FP, b: Vector2FP) bool {
        return a.x.eql(b.x) and a.y.eql(b.y);
    }
};

const expect = std.testing.expect;

const float_test_values = [_]f32{
    1.0,
    2.0,
    -0.3,
    10000.34,
};

test "Fp fromInt" {
    const a = FP.fromInt(1);
    try std.testing.expectApproxEqRel(a.toFloat(), 1, @sqrt(2.0 / 65536.0));
}

test "FP fromFloat" {
    const a: FP = FP.fromFrac(1, 10);
    try std.testing.expectApproxEqRel(a.toFloat(), 0.1, @sqrt(2.0 / 65536.0));
}

test "FP fromFormat" {
    const val = try FP.fromFormat("-1.2");
    try std.testing.expectApproxEqRel(val.toFloat(), -1.2, 2.0 / 65536.0);
}

test "FP add" {
    const a: FP = FP.fromInt(1).add(FP.fromInt(1).div(.fromInt(5)));
    const b: FP = FP.fromInt(-3).div(.fromInt(10));
    const c: FP = FP.fromInt(9).div(.fromInt(10));
    const val = a.add(b);
    try expect(val.aprxEql(c, FP.prec));
}

test "FP div" {
    const a: FP = FP.fromFrac(6, 5);
    const b: FP = FP.fromFrac(-3, 10);
    // 1.2 / (-0.3) = -4
    const c: FP = FP.fromInt(-4);
    const val = a.div(b);
    try expect(val.aprxEql(c, FP.sqrt(FP.prec)));
}

test "FP sqrt" {
    const a: FP = .fromFrac(9, 16);
    const c: FP = .fromFrac(3, 4);
    const val = a.sqrt();
    try expect(val.aprxEql(c, FP.prec.sqrt()));
}

test "FP radian range shift" {
    const a: FP = .fromFrac(-1, 10);
    const val = a.toPrincipleRadianRange();
    try expect(val.aprxEql(a, FP.prec));

    //const b: FP = .pi;
    //const b_val = b.toPrincipleRadianRange();
    //try expect(b_val.aprxEql(.zero, FP.prec));
}

test "FP atan" {
    const a: FP = FP.fromInt(1).atan();
    try std.testing.expectApproxEqRel(FP.pi_4.toFloat(), a.toFloat(), @sqrt(2.0 / 65536.0));
}

test "FP sin" {
    const a: FP = FP.pi.sin();
    try std.testing.expectApproxEqAbs(0, a.toFloat(), @sqrt(2.0 / 65536.0));

    const b: FP = FP.pi_2.sin();
    try std.testing.expectApproxEqAbs(1, b.toFloat(), @sqrt(2.0 / 65536.0));
}

test "FP cos" {
    const a: FP = FP.pi.cos();
    try std.testing.expectApproxEqAbs(-1, a.toFloat(), @sqrt(2.0 / 65536.0));

    const b: FP = FP.pi_2.cos();
    try std.testing.expectApproxEqAbs(0, b.toFloat(), @sqrt(2.0 / 65536.0));
}
