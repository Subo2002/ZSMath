const std = @import("std");
const Vector2 = @import("vector.zig").Vector2;
const Vector2I = @import("vector.zig").Vector2I;
const expect = std.testing.expect;

test "rounding" {
    const floaty: Vector2 = .init(-1.3, 0.5);
    try expect(floaty.round().eql(.init(-1, 1)));
}
