const std = @import("std");
const assert = std.debug.assert;

pub const IsFP = struct {
    int_bits: u32,
    frac_bits: u32,
    signedness: std.builtin.Signedness,

    pub inline fn isFP(a: anytype) IsFP {
        return @TypeOf(a).is_fp;
    }

    pub inline fn ToType(is_fp: IsFP) type {
        return FP(
            is_fp.int_bits,
            is_fp.frac_bits,
            is_fp.signedness,
        );
    }

    pub inline fn asFP(a: anytype) ToType(@TypeOf(a).is_fp) {
        return a;
    }
};

pub fn FP(int_size: u32, frac_size: u32, signedness: std.builtin.Signedness) type {
    const BackInt: type = @Type(.{ .int = .{
        .bits = int_size + frac_size,
        .signedness = signedness,
    } });
    const SignedBackInt: type = @Type(.{ .int = .{
        .bits = int_size + frac_size,
        .signedness = .signed,
    } });
    const BackInt2: type = @Type(.{ .int = .{
        .bits = (int_size + frac_size) * 2,
        .signedness = signedness,
    } });
    return struct {
        back: BackInt,

        pub const is_fp: IsFP = .{
            .int_bits = int_size,
            .frac_bits = frac_bits,
            .signedness = signedness,
        };
        const Self = @This();
        pub const frac_bits = frac_size;
        pub const int_bits = int_size;
        pub const bits = int_size + frac_size;
        pub const frac_scale = 1 << frac_bits;
        pub const prec: Self = Self{ .back = 2 }; // = 2 / frac_scale

        pub const zero: Self = .fromInt(0);
        pub const one: Self = .fromInt(1);
        pub const pi: Self = .fromFrac(355, 113);
        pub const min_one: Self = .fromInt(-1);
        pub const pi_2: Self = pi.div(.fromInt(2));
        pub const min_pi_2: Self = pi_2.mult(min_one);
        pub const pi_4: Self = pi_2.div(.fromInt(2));
        pub const min_pi: Self = .neg(pi);

        pub inline fn implCast(a: anytype) Self {
            const a_fp: IsFP = @TypeOf(a).is_fp;
            comptime assert(is_fp.int_bits >= a_fp.int_bits and is_fp.frac_bits >= a_fp.frac_bits);
            //std.debug.print("a: {}, new_frac_bits: {}, old_frac_bits: {}", .{
            //    a.back,
            //    frac_size,
            //    a_fp.frac_bits,
            //});
            return Self{ .back = @as(BackInt, @intCast(a.back)) << (frac_size - a_fp.frac_bits) };
        }

        pub inline fn cast(a: anytype) Self {
            const a_fp: IsFP = @TypeOf(a).is_fp;
            return Self{ .back = if (@as(SignedBackInt, @intCast(frac_size)) - @as(SignedBackInt, @intCast(a_fp.frac_bits)) >= 0)
                @intCast(a.back << (frac_size - a_fp.frac_bits))
            else
                @intCast(a.back >> (a_fp.frac_bits - frac_size)) };
        }

        pub fn fromFormat(comptime a: []const u8) !Self {
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
            const frac_10_size = std.math.pow(i32, 10, frac_len);
            const frac = try fromFormat_intPart(a[(int_end + 1)..]);
            const _frac = Self.fromFrac(frac, frac_10_size);
            return Self.fromInt(sign).mult(Self.fromInt(int).add(_frac));
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

        pub inline fn fromInt(i: i32) Self {
            return Self{
                .back = @as(BackInt, @intCast(i)) * frac_scale,
            };
        }

        pub inline fn fromFrac(a: i32, b: i32) Self {
            return Self.fromInt(a).div(.fromInt(b));
        }

        pub inline fn init(i: BackInt) Self {
            return Self{
                .back = i,
            };
        }

        pub inline fn toInt(f: Self) i32 {
            return @divTrunc(f.back, frac_scale);
        }

        pub inline fn getIntFrac(f: Self) u32 {
            return f.back - (@divTrunc(f.back, frac_scale) * frac_scale);
        }

        pub inline fn getFrac(f: Self) f32 {
            const frac_int = f.getIntFrac();
            return @as(f32, @floatFromInt(frac_int)) / @as(f32, @floatFromInt(Self.frac_scale));
        }

        pub inline fn fromFloat(f: f32) Self {
            //const int: i32 = @intFromFloat(f);
            //const frac: i32 = @intFromFloat((f - @as(f32, @floatFromInt(int))) * frac_scale);
            //std.debug.print("int: {}, frac: {}", .{ int, frac });
            //return FP{
            //    .back = (int << frac_bits) + frac,
            //};
            return Self{
                .back = @intFromFloat(f * frac_scale),
            };
        }

        pub inline fn toFloat(f: Self) f32 {
            const int = f.back >> frac_bits;
            const frac_part = f.back - (int << frac_bits);
            const frac: f32 = @as(f32, @floatFromInt(frac_part));
            return @as(f32, @floatFromInt(int)) + (frac / frac_scale);
        }

        pub inline fn add(a: Self, b: Self) Self {
            return Self{
                .back = a.back + b.back,
            };
        }

        pub inline fn addEql(a: *Self, b: Self) void {
            a.* = a.add(b);
        }

        pub inline fn sub(a: Self, b: Self) Self {
            if (signedness == .unsigned) assert(a.back >= b.back);
            return Self{
                .back = a.back - b.back,
            };
        }

        pub inline fn mult(a: Self, b: Self) Self {
            const a_back: BackInt2 = @intCast(a.back);
            const b_back: BackInt2 = @intCast(b.back);
            const ab_back: BackInt2 = (a_back * b_back) >> frac_bits;
            return .init(@intCast(ab_back));
        }

        pub inline fn div(a: Self, b: Self) Self {
            assert(b.back != 0);
            return Self{
                .back = @intCast(@divTrunc(@as(BackInt2, @intCast(a.back)) * frac_scale, b.back)),
            };
        }

        pub inline fn sqrt(a: Self) Self {
            assert(a.back >= 0);
            //this could be tightened up
            const b = FP2.UFP.implCast(a);
            const Int = @Type(.{ .int = .{
                .bits = FP2.UFP.bits + FP2.UFP.frac_bits,
                .signedness = .unsigned,
            } });
            const b_back = @as(Int, @intCast(b.back)) << FP2.UFP.frac_bits;
            const sqrt_b = FP2.UFP.init(
                @intCast(std.math.sqrt(b_back)),
            );
            return Self.cast(sqrt_b);
        }

        pub inline fn neg(a: Self) Self {
            return Self{
                .back = -a.back,
            };
        }

        //think of radians as -pi to pi as that's where the taylor approx. is good
        pub inline fn toPrincipleRadianRange(radian: Self) Self {
            const neg_pi = Self.pi.mult(.fromInt(-1));
            const pi2 = Self.pi.mult(.fromInt(2));
            var b = @mod(radian.back, pi2.back);
            if (b < neg_pi.back) {
                b += pi2.back;
            } else if (b > pi.back) {
                b -= pi2.back;
            }
            return Self{ .back = b };
        }

        pub fn sin(a: Self) Self {
            //sooo nice, range restriction is so good
            var x = a.toPrincipleRadianRange();
            if (x.greaterThan(.pi_2)) {
                x = Self.pi.sub(x);
            } else if (x.lessThan(Self.min_pi_2)) {
                x = Self.min_pi.sub(x);
            }
            const x_2 = x.mult(x);
            const x_3 = x.mult(x_2).div(.fromInt(-6));
            const x_5 = x_3.mult(x_2).div(.fromInt(-20));
            return x.add(x_3).add(x_5);
        }

        pub fn cos(a: Self) Self {
            const x = a.toPrincipleRadianRange();
            if (x.greaterThan(.pi_2)) {
                return Self.pi.sub(x).cosNice().neg();
            } else if (x.lessThan(.min_pi_2)) {
                return Self.min_pi.sub(x).cosNice().neg();
            } else {
                return x.cosNice();
            }
        }

        inline fn cosNice(x: Self) Self {
            assert(x.leq(.pi_2) and x.geq(.min_pi_2));
            const s = x.mult(x);
            const x_2 = s.div(.fromInt(-2));
            const x_4 = x_2.mult(s).div(.fromInt(-12));
            const x_6 = x_4.mult(s).div(.fromInt(-30));
            //const x_8 = x_6.mult(s).div(.fromInt(-56));
            return Self.one.add(x_2).add(x_4).add(x_6);
        }

        pub fn atan(a: Self) Self {
            if (a.greaterThan(.one)) {
                return pi_2.sub(atanSmallBetter(Self.one.div(a)));
            }
            if (a.lessThan(.min_one)) {
                return min_pi_2.sub(atanSmallBetter(Self.one.div(a)));
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

        inline fn atanSmallBetter(a: Self) Self {
            assert(a.abs().leq(.one));

            const b: Self = a.abs().sub(.one);

            //magic function nonesense
            const p = Self.fromFormat("0.2447") catch @compileError("invalid FP format");
            const q = Self.fromFormat("0.0663") catch @compileError("invalid FP format");
            const c: Self = p.add(q.mult(a.abs()));

            return a.mult(.pi_4).sub(a.mult(b).mult(c));
        }

        pub inline fn aprxEql(
            a: Self,
            b: Self, //comptime
            precision: Self,
        ) bool {
            const e = a.sub(b).back;
            const abs_e = if (e >= 0) e else -e;
            return abs_e < precision.back;
        }

        pub inline fn eql(a: Self, b: Self) bool {
            return a.back == b.back;
        }

        pub inline fn lessThan(a: Self, b: Self) bool {
            return a.back < b.back;
        }

        pub inline fn greaterThan(a: Self, b: Self) bool {
            return a.back > b.back;
        }

        pub inline fn leq(a: Self, b: Self) bool {
            return a.back <= b.back;
        }

        pub inline fn geq(a: Self, b: Self) bool {
            return a.back >= b.back;
        }

        pub inline fn abs(a: Self) Self {
            return if (a.geq(zero)) a else a.neg();
        }

        pub inline fn nonNeg(a: Self) bool {
            return a.geq(zero);
        }

        //pub inline fn max(a: FP, b: FP) FP {
        //    return if (a.lessThan(b))
        //}

        pub const UFP = FP(
            is_fp.int_bits,
            is_fp.frac_bits,
            std.builtin.Signedness.unsigned,
        );

        pub const SFP = FP(
            is_fp.int_bits,
            is_fp.frac_bits,
            std.builtin.Signedness.signed,
        );

        pub const UnitFP = FP(
            2,
            is_fp.int_bits + is_fp.frac_bits - 2,
            signedness,
        );

        pub fn multUnit(a: Self, b: UnitFP) Self {
            const IFP = FP(
                int_bits + UnitFP.int_bits,
                frac_bits + UnitFP.frac_bits,
                Self.is_fp.signedness,
            );
            return .cast(IFP.mult(.implCast(a), .implCast(b)));
        }

        pub fn multAny(a: anytype, b: anytype) Self {
            const a_is_fp: IsFP = IsFP.isFP(a);
            const b_is_fp: IsFP = IsFP.isFP(b);
            const IFP = FP(
                a_is_fp.int_bits + b_is_fp.int_bits,
                a_is_fp.frac_bits + b_is_fp.frac_bits,
                if (a_is_fp.signedness == .signed or
                    b_is_fp.signedness == .signed)
                    .signed
                else
                    .unsigned,
            );
            return .cast(IFP.mult(
                .implCast(IsFP.asFP(a)),
                .implCast(IsFP.asFP(b)),
            ));
        }

        pub fn addAny(a: anytype, b: anytype) Self {
            const a_is_fp: IsFP = IsFP.isFP(a);
            const b_is_fp: IsFP = IsFP.isFP(b);
            const IFP = FP(
                @as(u32, @intCast(@max(a_is_fp.int_bits, b_is_fp.int_bits))) + 1,
                @as(u32, @intCast(@max(a_is_fp.frac_bits, b_is_fp.frac_bits))),
                if (a_is_fp.signedness == .signed or
                    b_is_fp.signedness == .signed)
                    .signed
                else
                    .unsigned,
            );
            return .cast(IFP.add(
                .implCast(IsFP.asFP(a)),
                .implCast(IsFP.asFP(b)),
            ));
        }

        pub const FP2 = FP(
            is_fp.int_bits * 2,
            is_fp.frac_bits * 2,
            signedness,
        );
    };
}

const expect = std.testing.expect;

const float_test_values = [_]f32{
    1.0,
    2.0,
    -0.3,
    10000.34,
};

const FP16_16 = FP(16, 16, .signed);

test "Fp fromInt" {
    const a = FP16_16.fromInt(1);
    try std.testing.expectApproxEqRel(a.toFloat(), 1, @sqrt(2.0 / 65536.0));
}

test "FP fromFloat" {
    const a: FP16_16 = FP16_16.fromFrac(1, 10);
    try std.testing.expectApproxEqRel(a.toFloat(), 0.1, @sqrt(2.0 / 65536.0));
}

test "FP fromFormat" {
    const val = try FP16_16.fromFormat("-1.2");
    try std.testing.expectApproxEqRel(val.toFloat(), -1.2, 2.0 / 65536.0);
}

test "FP add" {
    const a: FP16_16 = FP16_16.fromInt(1).add(FP16_16.fromInt(1).div(.fromInt(5)));
    const b: FP16_16 = FP16_16.fromInt(-3).div(.fromInt(10));
    const c: FP16_16 = FP16_16.fromInt(9).div(.fromInt(10));
    const val = a.add(b);
    try expect(val.aprxEql(c, FP16_16.prec));
}

test "FP div" {
    const a: FP16_16 = FP16_16.fromFrac(6, 5);
    const b: FP16_16 = FP16_16.fromFrac(-3, 10);
    // 1.2 / (-0.3) = -4
    const c: FP16_16 = FP16_16.fromInt(-4);
    const val = a.div(b);
    try expect(val.aprxEql(c, FP16_16.sqrt(FP16_16.prec)));
}

test "FP sqrt" {
    const a: FP16_16 = .fromFrac(9, 16);
    const c: FP16_16 = .fromFrac(3, 4);
    const val = a.sqrt();
    try expect(val.aprxEql(c, FP16_16.prec.sqrt()));
}

test "FP radian range shift" {
    const a: FP16_16 = .fromFrac(-1, 10);
    const val = a.toPrincipleRadianRange();
    try expect(val.aprxEql(a, FP16_16.prec));

    //const b: FP = .pi;
    //const b_val = b.toPrincipleRadianRange();
    //try expect(b_val.aprxEql(.zero, FP.prec));
}

test "FP atan" {
    const a: FP16_16 = FP16_16.fromInt(1).atan();
    try std.testing.expectApproxEqRel(FP16_16.pi_4.toFloat(), a.toFloat(), @sqrt(2.0 / 65536.0));
}

test "FP sin" {
    const a: FP16_16 = FP16_16.pi.sin();
    try std.testing.expectApproxEqAbs(0, a.toFloat(), @sqrt(2.0 / 65536.0));

    const b: FP16_16 = FP16_16.pi_2.sin();
    try std.testing.expectApproxEqAbs(1, b.toFloat(), @sqrt(2.0 / 65536.0));
}

test "FP cos" {
    const a: FP16_16 = FP16_16.pi.cos();
    try std.testing.expectApproxEqAbs(-1, a.toFloat(), @sqrt(2.0 / 65536.0));

    const b: FP16_16 = FP16_16.pi_2.cos();
    try std.testing.expectApproxEqAbs(0, b.toFloat(), @sqrt(2.0 / 65536.0));
}
