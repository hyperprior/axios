// Pure dialogue data and state machine. No raylib dependency.

const std = @import("std");
const Flag = @import("flags.zig").Flag;
const Flags = @import("flags.zig").Flags;
const QuestId = @import("quest.zig").QuestId;
const QuestStage = @import("quest.zig").QuestStage;
const Virtue = @import("formation.zig").Virtue;

pub const Effect = struct {
    grant_flag: Flag = .none,
    start_quest: ?QuestId = null,
    advance_quest: ?QuestId = null,
    quest_stage: QuestStage = .not_started,
    virtue: ?Virtue = null,
    virtue_amount: i8 = 0,
};

pub const no_effect = Effect{};

pub const Choice = struct {
    text: []const u8,
    next_node: u16,
    effect: Effect = no_effect,
};

pub const Node = struct {
    speaker: []const u8,
    text: []const u8,
    choices: []const Choice = &.{},
    next_node: ?u16 = null,
    effect: Effect = no_effect, // effect applied when this node is reached
};

pub const Dialogue = struct {
    id: []const u8,
    nodes: []const Node,
    grants: Flag = .none,
};

pub const DialogueState = struct {
    active: bool = false,
    dialogue: ?*const Dialogue = null,
    current_node: u16 = 0,
    selected_choice: u8 = 0,
    // Effects to be applied by the game state after each advance
    pending_effect: Effect = no_effect,

    pub fn start(self: *DialogueState, dialogue: *const Dialogue) void {
        self.active = true;
        self.dialogue = dialogue;
        self.current_node = 0;
        self.selected_choice = 0;
        self.pending_effect = no_effect;
        // Apply effect of first node if any
        if (dialogue.nodes.len > 0) {
            self.pending_effect = dialogue.nodes[0].effect;
        }
    }

    pub fn currentNode(self: *const DialogueState) ?*const Node {
        const d = self.dialogue orelse return null;
        if (self.current_node >= d.nodes.len) return null;
        return &d.nodes[self.current_node];
    }

    pub fn hasChoices(self: *const DialogueState) bool {
        const node = self.currentNode() orelse return false;
        return node.choices.len > 0;
    }

    pub fn choiceCount(self: *const DialogueState) u8 {
        const node = self.currentNode() orelse return 0;
        return @intCast(node.choices.len);
    }

    pub fn selectUp(self: *DialogueState) void {
        if (self.selected_choice > 0) {
            self.selected_choice -= 1;
        }
    }

    pub fn selectDown(self: *DialogueState) void {
        const count = self.choiceCount();
        if (count > 0 and self.selected_choice < count - 1) {
            self.selected_choice += 1;
        }
    }

    // Advance dialogue. Returns the grant flag if dialogue ended.
    pub fn advance(self: *DialogueState) Flag {
        const node = self.currentNode() orelse {
            return self.closeAndGrant();
        };

        self.pending_effect = no_effect;

        if (node.choices.len > 0) {
            const choice = &node.choices[self.selected_choice];
            self.pending_effect = choice.effect;
            self.current_node = choice.next_node;
        } else if (node.next_node) |next| {
            self.current_node = next;
        } else {
            return self.closeAndGrant();
        }

        self.selected_choice = 0;

        const d = self.dialogue orelse return self.closeAndGrant();
        if (self.current_node >= d.nodes.len) {
            return self.closeAndGrant();
        }

        // Merge node effect
        const new_node = &d.nodes[self.current_node];
        self.pending_effect = mergeEffects(self.pending_effect, new_node.effect);

        return .none;
    }

    fn closeAndGrant(self: *DialogueState) Flag {
        const flag = if (self.dialogue) |d| d.grants else .none;
        self.close();
        return flag;
    }

    pub fn close(self: *DialogueState) void {
        self.active = false;
        self.dialogue = null;
        self.current_node = 0;
        self.selected_choice = 0;
        self.pending_effect = no_effect;
    }
};

fn mergeEffects(a: Effect, b: Effect) Effect {
    return .{
        .grant_flag = if (b.grant_flag != .none) b.grant_flag else a.grant_flag,
        .start_quest = b.start_quest orelse a.start_quest,
        .advance_quest = b.advance_quest orelse a.advance_quest,
        .quest_stage = if (b.quest_stage != .not_started) b.quest_stage else a.quest_stage,
        .virtue = b.virtue orelse a.virtue,
        .virtue_amount = if (b.virtue_amount != 0) b.virtue_amount else a.virtue_amount,
    };
}

// --- Tests ---

const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;

const test_dialogue = Dialogue{
    .id = "test",
    .grants = .spoke_to_theophilos,
    .nodes = &.{
        .{
            .speaker = "Anna",
            .text = "Peace be with you. Are you the new catechumen?",
            .choices = &.{
                .{ .text = "Yes, Father Theophilos sent me.", .next_node = 1, .effect = .{ .virtue = .humility, .virtue_amount = 2 } },
                .{ .text = "Who are you?", .next_node = 2 },
            },
        },
        .{
            .speaker = "Anna",
            .text = "Good. We have much work to do today.",
            .next_node = 3,
        },
        .{
            .speaker = "Anna",
            .text = "I am Anna, deaconess of this parish.",
            .next_node = 1,
        },
        .{
            .speaker = "Anna",
            .text = "Come, let me show you what needs doing.",
        },
    },
};

test "dialogue starts at node 0" {
    var ds = DialogueState{};
    ds.start(&test_dialogue);
    try expect(ds.active);
    try expect(ds.current_node == 0);
}

test "dialogue has choices" {
    var ds = DialogueState{};
    ds.start(&test_dialogue);
    try expect(ds.hasChoices());
    try expect(ds.choiceCount() == 2);
}

test "selecting choice advances and captures effect" {
    var ds = DialogueState{};
    ds.start(&test_dialogue);
    ds.selected_choice = 0; // humble response
    const flag = ds.advance();
    try expect(flag == .none);
    try expect(ds.current_node == 1);
    try expect(ds.pending_effect.virtue.? == .humility);
    try expect(ds.pending_effect.virtue_amount == 2);
}

test "dialogue ends and grants flag" {
    var ds = DialogueState{};
    ds.start(&test_dialogue);
    ds.selected_choice = 0;
    _ = ds.advance(); // 0 -> 1
    _ = ds.advance(); // 1 -> 3
    const flag = ds.advance(); // 3 terminal
    try expect(flag == .spoke_to_theophilos);
    try expect(!ds.active);
}

test "select up and down" {
    var ds = DialogueState{};
    ds.start(&test_dialogue);
    ds.selectDown();
    try expect(ds.selected_choice == 1);
    ds.selectUp();
    try expect(ds.selected_choice == 0);
}

test "close resets state" {
    var ds = DialogueState{};
    ds.start(&test_dialogue);
    ds.close();
    try expect(!ds.active);
}
