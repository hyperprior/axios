// Pure dialogue data and state machine. No raylib dependency.

const std = @import("std");
const Flag = @import("flags.zig").Flag;
const Flags = @import("flags.zig").Flags;

pub const Choice = struct {
    text: []const u8,
    next_node: u16, // index into dialogue's nodes array
};

pub const Node = struct {
    speaker: []const u8,
    text: []const u8,
    choices: []const Choice = &.{},
    next_node: ?u16 = null, // auto-advance if no choices (null = end)
};

pub const Dialogue = struct {
    id: []const u8,
    nodes: []const Node,
    grants: Flag = .none, // flag granted when this dialogue completes
};

pub const DialogueState = struct {
    active: bool = false,
    dialogue: ?*const Dialogue = null,
    current_node: u16 = 0,
    selected_choice: u8 = 0,

    pub fn start(self: *DialogueState, dialogue: *const Dialogue) void {
        self.active = true;
        self.dialogue = dialogue;
        self.current_node = 0;
        self.selected_choice = 0;
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

    // Advance dialogue. Returns the granted flag if dialogue ended, .none otherwise.
    pub fn advance(self: *DialogueState) Flag {
        const node = self.currentNode() orelse {
            return self.closeAndGrant();
        };

        if (node.choices.len > 0) {
            const choice = &node.choices[self.selected_choice];
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
    }
};

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
                .{ .text = "Yes, Father Theophilos sent me.", .next_node = 1 },
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
            .text = "I am Anna, deaconess of this parish. I help organize the charitable work.",
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
    const node = ds.currentNode().?;
    try expectEqualStrings("Anna", node.speaker);
}

test "dialogue has choices" {
    var ds = DialogueState{};
    ds.start(&test_dialogue);
    try expect(ds.hasChoices());
    try expect(ds.choiceCount() == 2);
}

test "selecting choice advances to correct node" {
    var ds = DialogueState{};
    ds.start(&test_dialogue);
    ds.selected_choice = 0;
    const flag = ds.advance();
    try expect(flag == .none);
    try expect(ds.current_node == 1);
}

test "second choice goes to different node" {
    var ds = DialogueState{};
    ds.start(&test_dialogue);
    ds.selected_choice = 1;
    const flag = ds.advance();
    try expect(flag == .none);
    try expect(ds.current_node == 2);
}

test "auto-advance follows next_node" {
    var ds = DialogueState{};
    ds.start(&test_dialogue);
    ds.selected_choice = 0;
    _ = ds.advance(); // node 0 -> 1
    const flag = ds.advance(); // node 1 -> 3 (auto)
    try expect(flag == .none);
    try expect(ds.current_node == 3);
}

test "dialogue ends at terminal node and grants flag" {
    var ds = DialogueState{};
    ds.start(&test_dialogue);
    ds.selected_choice = 0;
    _ = ds.advance(); // 0 -> 1
    _ = ds.advance(); // 1 -> 3
    const flag = ds.advance(); // 3 is terminal
    try expect(flag == .spoke_to_theophilos);
    try expect(!ds.active);
}

test "select up and down" {
    var ds = DialogueState{};
    ds.start(&test_dialogue);
    try expect(ds.selected_choice == 0);
    ds.selectDown();
    try expect(ds.selected_choice == 1);
    ds.selectDown();
    try expect(ds.selected_choice == 1);
    ds.selectUp();
    try expect(ds.selected_choice == 0);
    ds.selectUp();
    try expect(ds.selected_choice == 0);
}

test "close resets state" {
    var ds = DialogueState{};
    ds.start(&test_dialogue);
    ds.close();
    try expect(!ds.active);
    try expect(ds.dialogue == null);
}
