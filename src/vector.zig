const std = @import("std");
const assert = std.debug.assert;

pub const IsVector2Int = struct {
    int: type,

    pub inline fn asVector2I(a: anytype) MakeVector2Int(@TypeOf(a).is_vector2I.int) {
        return a;
    }
};

pub fn MakeVector2Int(Int: type) type {
    std.debug.assert(@typeInfo(Int) == .int);
    return struct {
        x: Int,
        y: Int,

        pub const is_vector2I: IsVector2Int = .{ .int = Int };
        const Vector2Int = @This();

        pub const zero: Vector2Int = .init(0, 0);

        pub inline fn init(x: Int, y: Int) Vector2Int {
            return .{ .x = x, .y = y };
        }

        pub inline fn implCast(a: anytype) Vector2Int {
            const b = IsVector2Int.asVector2I(a);
            return .init(b.x, b.y);
        }

        pub inline fn cast(a: anytype) Vector2Int {
            const b = IsVector2Int.asVector2I(a);
            return .init(@intCast(b.x), @intCast(b.y));
        }

        pub inline fn add(a: Vector2Int, b: Vector2Int) Vector2Int {
            return .{ .x = a.x + b.x, .y = a.y + b.y };
        }

        pub inline fn sub(a: Vector2Int, b: Vector2Int) Vector2Int {
            return .{ .x = a.x - b.x, .y = a.y - b.y };
        }

        pub inline fn mult(a: Vector2Int, b: Vector2Int) Vector2Int {
            return .{ .x = a.x * b.x, .y = a.y * b.y };
        }

        pub inline fn div(a: Vector2Int, b: Vector2Int) Vector2Int {
            return .{ .x = @divTrunc(a.x, b.x), .y = @divTrunc(a.y, b.y) };
        }

        pub inline fn scale(a: Vector2Int, c: Int) Vector2Int {
            return .{ .x = a.x * c, .y = a.y * c };
        }

        pub inline fn divScale(a: Vector2Int, c: Int) Vector2Int {
            return .{ .x = @divTrunc(a.x, c), .y = @divTrunc(a.y, c) };
        }

        pub inline fn toFloat(a: Vector2Int) Vector2 {
            return .{ .x = @floatFromInt(a.x), .y = @floatFromInt(a.y) };
        }

        pub inline fn toDouble(a: Vector2Int) Vector2B {
            return .{ .x = @floatFromInt(a.x), .y = @floatFromInt(a.y) };
        }

        pub inline fn eql(a: Vector2Int, b: Vector2Int) bool {
            return a.x == b.x and a.y == b.y;
        }

        pub inline fn dot(a: Vector2Int, b: Vector2Int) i32 {
            return a.x * b.x + a.y * b.y;
        }

        pub inline fn neg(a: Vector2Int) Vector2Int {
            comptime std.debug.assert(@typeInfo(Int).int.signedness == .signed);
            return .init(-a.x, -a.y);
        }

        pub inline fn shlScalar(a: Vector2Int, b: u8) Vector2Int {
            return .init(a.x << b, a.y << b);
        }

        pub inline fn shlVec(a: Vector2Int, b: Vector2Int) Vector2Int {
            return .init(a.x << b.x, a.x << b.x);
        }

        pub inline fn shrScalar(a: Vector2Int, b: u8) Vector2Int {
            return .init(a.x >> b, a.y >> b);
        }

        pub inline fn shrVec(a: Vector2Int, b: Vector2Int) Vector2Int {
            return .init(a.x >> b.x, a.y >> b.y);
        }

        pub inline fn andScalar(a: Vector2Int, b: Int) Vector2Int {
            return .init(a.x & b, a.y & b);
        }

        pub inline fn andVec(a: Vector2Int, b: Vector2Int) Vector2Int {
            return .init(a.x & b.x, a.y & b.y);
        }

        pub inline fn orScalar(a: Vector2Int, b: Int) Vector2Int {
            return .init(a.x | b, a.y | b);
        }

        pub inline fn orVec(a: Vector2Int, b: Vector2Int) Vector2Int {
            return .init(a.x | b.x, a.y | b.y);
        }

        pub inline fn not(a: Vector2Int) Vector2Int {
            return .init(~a.x, ~a.y);
        }
    };
}

test "Vector2I implCast" {
    const Vector2I16 = MakeVector2Int(i16);
    const Vector2I17 = MakeVector2Int(i17);
    const a: Vector2I16 = .init(10, 10);
    try std.testing.expect(Vector2I17.implCast(a).eql(.init(10, 10)));
}

test "Vector2I cast" {
    const Vector2I16 = MakeVector2Int(i16);
    const Vector2U16 = MakeVector2Int(u16);
    const a: Vector2I16 = .init(10, 10);
    try std.testing.expect(Vector2U16.cast(a).eql(.init(10, 10)));
}

test "Vector2I bitmask" {
    const Vector2I16 = MakeVector2Int(i16);
    const a: Vector2I16 = .init(10, 10);
    const a_and_7 = a.andScalar(7);
    try std.testing.expect(a_and_7.eql(.init(2, 2)));
}

pub const Vector2 = struct {
    x: f32,
    y: f32,

    const Vector2I = MakeVector2Int(i32);

    pub const zero: Vector2 = .{ .x = 0, .y = 0 };

    pub inline fn init(x: f32, y: f32) Vector2 {
        return .{ .x = x, .y = y };
    }

    pub inline fn add(a: Vector2, b: Vector2) Vector2 {
        return .{ .x = a.x + b.x, .y = a.y + b.y };
    }

    pub inline fn sub(a: Vector2, b: Vector2) Vector2 {
        return .{ .x = a.x - b.x, .y = a.y - b.y };
    }

    pub inline fn mult(a: Vector2, b: Vector2) Vector2 {
        return .{ .x = a.x * b.x, .y = a.y * b.y };
    }

    pub inline fn div(a: Vector2, b: Vector2) Vector2 {
        return .{ .x = a.x / b.x, .y = a.y / b.y };
    }

    pub inline fn scale(a: Vector2, c: f32) Vector2 {
        return .{ .x = a.x * c, .y = a.y * c };
    }

    pub inline fn toVector2B(a: Vector2) Vector2B {
        return .{ .x = a.x, .y = a.y };
    }

    pub inline fn round(a: Vector2) Vector2I {
        return .init(@intFromFloat(@round(a.x)), @intFromFloat(@round(a.y)));
    }

    pub inline fn eql(a: Vector2, b: Vector2) bool {
        return a.x == b.x and a.y == b.y;
    }

    pub inline fn length(a: Vector2) f32 {
        return std.math.sqrt(a.x * a.x + a.y * a.y);
    }

    pub inline fn normalize(a: Vector2) Vector2 {
        return a.scale(1 / length(a));
    }

    pub inline fn lengthSquared(a: Vector2) f32 {
        return a.x * a.x + a.y * a.y;
    }

    pub inline fn dircVec(a: f32) Vector2 {
        return init(std.math.cos(a), std.math.sin(a));
    }

    pub inline fn compAngle(a: Vector2) f32 {
        var angle: f64 = std.math.atan(a.y / a.x);
        if (a.x < 0) angle += if (a.y >= 0) std.math.pi else -std.math.pi;
        return @floatCast(angle);
    }

    pub inline fn dot(a: Vector2, b: Vector2) f32 {
        return a.x * b.x + a.y * b.y;
    }

    pub inline fn neg(a: Vector2) Vector2 {
        return .init(-a.x, -a.y);
    }
};

pub const Vector2B = struct {
    x: f64,
    y: f64,

    const Vector2i32 = MakeVector2Int(i32);
    pub const zero: Vector2B = .{ .x = 0, .y = 0 };

    pub inline fn init(x: f64, y: f64) Vector2B {
        return .{ .x = x, .y = y };
    }

    pub inline fn add(a: Vector2B, b: Vector2B) Vector2B {
        return .{ .x = a.x + b.x, .y = a.y + b.y };
    }

    pub inline fn sub(a: Vector2B, b: Vector2B) Vector2B {
        return .{ .x = a.x - b.x, .y = a.y - b.y };
    }

    pub inline fn mult(a: Vector2B, b: Vector2B) Vector2B {
        return .{ .x = a.x * b.x, .y = a.y * b.y };
    }

    pub inline fn div(a: Vector2B, b: Vector2B) Vector2B {
        return .{ .x = a.x / b.x, .y = a.y / b.y };
    }

    pub inline fn scale(a: Vector2B, c: f64) Vector2B {
        return .{ .x = a.x * c, .y = a.y * c };
    }

    pub inline fn trunc(a: Vector2B) Vector2 {
        return .{
            .x = @floatCast(a.x),
            .y = @floatCast(a.y),
        };
    }

    pub inline fn round(a: Vector2) Vector2i32 {
        .init(@intCast(@round(a.x)), @intCast(@round(a.y)));
    }

    pub inline fn eql(a: Vector2B, b: Vector2B) bool {
        return a.x == b.x and a.y == b.y;
    }

    pub inline fn length(a: Vector2B) f64 {
        return std.math.sqrt(a.x * a.x + a.y * a.y);
    }

    pub inline fn lengthSquared(a: Vector2B) f64 {
        return a.x * a.x + a.y * a.y;
    }

    pub inline fn dot(a: Vector2B, b: Vector2B) Vector2B {
        a.x * b.x + a.y * b.y;
    }

    pub inline fn neg(a: Vector2B) Vector2B {
        return .init(-a.x, -a.y);
    }
};
