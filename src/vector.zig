const std = @import("std");

pub const Vector2I = struct {
    x: i32,
    y: i32,

    pub const zero: Vector2I = .{ .x = 0, .y = 0 };

    pub inline fn init(x: i32, y: i32) Vector2I {
        return .{ .x = x, .y = y };
    }

    pub inline fn add(a: Vector2I, b: Vector2I) Vector2I {
        return .{ .x = a.x + b.x, .y = a.y + b.y };
    }

    pub inline fn sub(a: Vector2I, b: Vector2I) Vector2I {
        return .{ .x = a.x - b.x, .y = a.y - b.y };
    }

    pub inline fn mult(a: Vector2I, b: Vector2I) Vector2I {
        return .{ .x = a.x * b.x, .y = a.y * b.y };
    }

    pub inline fn div(a: Vector2I, b: Vector2I) Vector2I {
        return .{ .x = @divTrunc(a.x, b.x), .y = @divTrunc(a.y, b.y) };
    }

    pub inline fn scale(a: Vector2I, c: i32) Vector2I {
        return .{ .x = a.x * c, .y = a.y * c };
    }

    pub inline fn divScale(a: Vector2I, c: i32) Vector2I {
        return .{ .x = @divTrunc(a.x, c), .y = @divTrunc(a.y, c) };
    }

    pub inline fn toFloat(a: Vector2I) Vector2 {
        return .{ .x = @floatFromInt(a.x), .y = @floatFromInt(a.y) };
    }

    pub inline fn toDouble(a: Vector2I) Vector2B {
        return .{ .x = @floatFromInt(a.x), .y = @floatFromInt(a.y) };
    }

    pub inline fn eql(a: Vector2I, b: Vector2I) bool {
        return a.x == b.x and a.y == b.y;
    }
};

pub const Vector2 = struct {
    x: f32,
    y: f32,

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
        if (a.x > 10_000.0 or a.x < -10_000.0 or a.y > 10_000.0 or a.y < -10_000.0) {
            std.debug.print("big value: ({}, {})", .{ a.x, a.y });
            return Vector2I.zero;
        }
        var b: Vector2I = .{ .x = @intFromFloat(a.x), .y = @intFromFloat(a.y) };
        if (a.x - @as(f32, @floatFromInt(b.x)) >= 0.5)
            b.x += 1;
        if (a.y - @as(f32, @floatFromInt(b.y)) >= 0.5)
            b.y += 1;
        return b;
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
};

pub const Vector2B = struct {
    x: f64,
    y: f64,

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

    pub inline fn round(a: Vector2) Vector2I {
        const sx: f32 = if (a.x >= 0) 1 else -1;
        const sy: f32 = if (a.y >= 0) 1 else -1;

        const c: Vector2I = .init(a.x * sx, a.y * sy);
        var b: Vector2I = .{ .x = @intFromFloat(c.x), .y = @intFromFloat(c.y) };
        if (c.x - @as(f64, @floatFromInt(b.y)) >= 0.5)
            b.x += 1;
        if (c.y - @as(f64, @floatFromInt(b.y)) >= 0.5)
            b.y += 1;
        return .init(b.x * @as(i32, @intFromFloat(sx)), b.y * @as(i32, @intFromFloat(sy)));
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
};
