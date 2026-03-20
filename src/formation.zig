// Formation tracking — virtues shaped by player choices. No raylib dependency.
// These are soft internal values, not heavy RPG stats.

const std = @import("std");

pub const Virtue = enum(u8) {
    mercy,
    truth,
    humility,
    courage,
    faithfulness,
};

const virtue_count = 5;

pub const Formation = struct {
    values: [virtue_count]i8 = [_]i8{0} ** virtue_count,

    pub fn get(self: *const Formation, v: Virtue) i8 {
        return self.values[@intFromEnum(v)];
    }

    pub fn add(self: *Formation, v: Virtue, amount: i8) void {
        const idx = @intFromEnum(v);
        const result = @as(i16, self.values[idx]) + amount;
        self.values[idx] = @intCast(std.math.clamp(result, -100, 100));
    }

    pub fn dominant(self: *const Formation) ?Virtue {
        var best: ?Virtue = null;
        var best_val: i8 = 0;
        for (0..virtue_count) |i| {
            if (self.values[i] > best_val) {
                best_val = self.values[i];
                best = @enumFromInt(i);
            }
        }
        return best;
    }

    pub fn reset(self: *Formation) void {
        self.values = [_]i8{0} ** virtue_count;
    }
};

// --- Tests ---

const expect = std.testing.expect;

test "formation starts at zero" {
    const f = Formation{};
    try expect(f.get(.mercy) == 0);
    try expect(f.get(.truth) == 0);
}

test "add virtue" {
    var f = Formation{};
    f.add(.mercy, 3);
    try expect(f.get(.mercy) == 3);
    f.add(.mercy, 2);
    try expect(f.get(.mercy) == 5);
}

test "virtue can be negative" {
    var f = Formation{};
    f.add(.truth, -2);
    try expect(f.get(.truth) == -2);
}

test "virtue clamps to range" {
    var f = Formation{};
    f.add(.courage, 120);
    try expect(f.get(.courage) == 100);
    f.add(.courage, -120);
    f.add(.courage, -120);
    try expect(f.get(.courage) == -100);
}

test "dominant virtue" {
    var f = Formation{};
    f.add(.mercy, 5);
    f.add(.truth, 3);
    f.add(.humility, 7);
    try expect(f.dominant().? == .humility);
}

test "no dominant when all zero" {
    const f = Formation{};
    try expect(f.dominant() == null);
}

test "reset clears all" {
    var f = Formation{};
    f.add(.mercy, 5);
    f.add(.truth, 3);
    f.reset();
    try expect(f.get(.mercy) == 0);
    try expect(f.get(.truth) == 0);
}
