// Quest system — tracks quest stages and objectives. No raylib dependency.

const std = @import("std");
const Flag = @import("flags.zig").Flag;

pub const QuestId = enum(u8) {
    first_instruction,
    widows_oil,
    false_rumor,
    _,
};

pub const QuestStage = enum(u8) {
    not_started,
    // First Instruction stages
    fi_talk_to_anna,
    fi_talk_to_stephanos,
    fi_return_to_theophilos,
    fi_complete,
    // Widow's Oil stages
    wo_visit_helena,
    wo_investigate_markos,
    wo_talk_to_diodoros,
    wo_decide_resolution,
    wo_complete,
    // False Rumor stages (placeholder for now)
    fr_hear_rumor,
    fr_investigate,
    fr_decide,
    fr_complete,
    _,
};

pub const Objective = struct {
    text: []const u8,
    complete: bool = false,
};

pub const Quest = struct {
    id: QuestId,
    name: []const u8,
    stage: QuestStage = .not_started,
    description: []const u8,

    pub fn isActive(self: *const Quest) bool {
        return self.stage != .not_started and !self.isComplete();
    }

    pub fn isComplete(self: *const Quest) bool {
        return switch (self.id) {
            .first_instruction => self.stage == .fi_complete,
            .widows_oil => self.stage == .wo_complete,
            .false_rumor => self.stage == .fr_complete,
            _ => false,
        };
    }

    pub fn currentObjective(self: *const Quest) ?[]const u8 {
        return switch (self.stage) {
            .not_started => null,
            // First Instruction
            .fi_talk_to_anna => "Speak with Anna in the courtyard",
            .fi_talk_to_stephanos => "Find Stephanos near the church",
            .fi_return_to_theophilos => "Return to Father Theophilos",
            .fi_complete => null,
            // Widow's Oil
            .wo_visit_helena => "Visit Helena in the residential lane",
            .wo_investigate_markos => "Speak with Markos at the market",
            .wo_talk_to_diodoros => "Ask Diodoros at the loading court",
            .wo_decide_resolution => "Decide how to resolve Helena's need",
            .wo_complete => null,
            // False Rumor
            .fr_hear_rumor => "Listen to what people are saying",
            .fr_investigate => "Investigate the source of the rumor",
            .fr_decide => "Decide how to respond",
            .fr_complete => null,
            _ => null,
        };
    }
};

pub const QuestLog = struct {
    quests: [3]Quest = .{
        .{ .id = .first_instruction, .name = "First Instruction", .description = "Father Theophilos has tasks for you before the evening gathering." },
        .{ .id = .widows_oil, .name = "The Widow's Oil", .description = "Helena, a widow, was promised oil that never arrived." },
        .{ .id = .false_rumor, .name = "A False Rumor", .description = "A troubling rumor is spreading through the district." },
    },

    pub fn get(self: *QuestLog, id: QuestId) *Quest {
        return &self.quests[@intFromEnum(id)];
    }

    pub fn getConst(self: *const QuestLog, id: QuestId) *const Quest {
        return &self.quests[@intFromEnum(id)];
    }

    pub fn start(self: *QuestLog, id: QuestId) void {
        const q = self.get(id);
        if (q.stage == .not_started) {
            q.stage = switch (id) {
                .first_instruction => .fi_talk_to_anna,
                .widows_oil => .wo_visit_helena,
                .false_rumor => .fr_hear_rumor,
                _ => return,
            };
        }
    }

    pub fn advance(self: *QuestLog, id: QuestId, to: QuestStage) void {
        self.get(id).stage = to;
    }

    pub fn activeQuest(self: *const QuestLog) ?*const Quest {
        for (&self.quests) |*q| {
            if (q.isActive()) return q;
        }
        return null;
    }

    pub fn activeObjective(self: *const QuestLog) ?[]const u8 {
        if (self.activeQuest()) |q| {
            return q.currentObjective();
        }
        return null;
    }
};

// --- Tests ---

const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;

test "quest starts not_started" {
    const log = QuestLog{};
    try expect(log.getConst(.first_instruction).stage == .not_started);
    try expect(!log.getConst(.first_instruction).isActive());
}

test "start quest sets first stage" {
    var log = QuestLog{};
    log.start(.first_instruction);
    try expect(log.getConst(.first_instruction).stage == .fi_talk_to_anna);
    try expect(log.getConst(.first_instruction).isActive());
}

test "advance quest to next stage" {
    var log = QuestLog{};
    log.start(.first_instruction);
    log.advance(.first_instruction, .fi_talk_to_stephanos);
    try expect(log.getConst(.first_instruction).stage == .fi_talk_to_stephanos);
}

test "quest complete" {
    var log = QuestLog{};
    log.start(.first_instruction);
    log.advance(.first_instruction, .fi_complete);
    try expect(log.getConst(.first_instruction).isComplete());
    try expect(!log.getConst(.first_instruction).isActive());
}

test "active objective text" {
    var log = QuestLog{};
    log.start(.first_instruction);
    const obj = log.activeObjective().?;
    try expectEqualStrings("Speak with Anna in the courtyard", obj);
}

test "no active objective when nothing started" {
    const log = QuestLog{};
    try expect(log.activeObjective() == null);
}

test "widows oil quest flow" {
    var log = QuestLog{};
    log.start(.widows_oil);
    try expectEqualStrings("Visit Helena in the residential lane", log.activeObjective().?);
    log.advance(.widows_oil, .wo_investigate_markos);
    try expectEqualStrings("Speak with Markos at the market", log.activeObjective().?);
    log.advance(.widows_oil, .wo_talk_to_diodoros);
    try expectEqualStrings("Ask Diodoros at the loading court", log.activeObjective().?);
    log.advance(.widows_oil, .wo_complete);
    try expect(log.activeObjective() == null);
}
