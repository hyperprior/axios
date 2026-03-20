// NPC data and interaction logic. No raylib dependency.

const std = @import("std");
const Dialogue = @import("dialogue.zig").Dialogue;
const Flag = @import("flags.zig").Flag;
const Flags = @import("flags.zig").Flags;

const interaction_radius: f32 = 50.0;

pub const Npc = struct {
    name: []const u8,
    x: f32,
    y: f32,
    dialogue: *const Dialogue,
    size: f32 = 20,
    requires: Flag = .none, // NPC only appears when this flag is set (.none = always visible)

    pub fn isVisible(self: *const Npc, flags: *const Flags) bool {
        return self.requires == .none or flags.has(self.requires);
    }

    pub fn distanceTo(self: *const Npc, px: f32, py: f32) f32 {
        const dx = self.x - px;
        const dy = self.y - py;
        return @sqrt(dx * dx + dy * dy);
    }

    pub fn canInteract(self: *const Npc, px: f32, py: f32) bool {
        return self.distanceTo(px, py) < interaction_radius;
    }
};

pub fn findInteractable(npcs: []const Npc, px: f32, py: f32, flags: *const Flags) ?usize {
    var closest_dist: f32 = interaction_radius;
    var closest_idx: ?usize = null;

    for (npcs, 0..) |*npc, i| {
        if (!npc.isVisible(flags)) continue;
        const dist = npc.distanceTo(px, py);
        if (dist < closest_dist) {
            closest_dist = dist;
            closest_idx = i;
        }
    }

    return closest_idx;
}

// --- Dialogue content for MVP NPCs ---

pub const theophilos_dialogue = Dialogue{
    .id = "theophilos_intro",
    .grants = .spoke_to_theophilos,
    .nodes = &.{
        .{
            .speaker = "Father Theophilos",
            .text = "Ah, you have come. The Lord's timing is perfect, as always.",
            .choices = &.{
                .{ .text = "Father, I am ready to serve.", .next_node = 1 },
                .{ .text = "What would you have me do?", .next_node = 2 },
                .{ .text = "I am still learning my way around.", .next_node = 3 },
            },
        },
        .{
            .speaker = "Father Theophilos",
            .text = "Good. A willing heart is the beginning of wisdom. Anna in the courtyard has need of help today. Speak with her.",
        },
        .{
            .speaker = "Father Theophilos",
            .text = "Today there are errands to be done, and people to be helped. Find Anna -- she will guide you.",
        },
        .{
            .speaker = "Father Theophilos",
            .text = "That is no shame. Walk the district, speak to the people, and the city will teach you. But first, find Anna near the courtyard.",
        },
    },
};

pub const anna_dialogue = Dialogue{
    .id = "anna_intro",
    .grants = .spoke_to_anna,
    .nodes = &.{
        .{
            .speaker = "Anna",
            .text = "Peace be with you. You must be the catechumen Father Theophilos spoke of.",
            .choices = &.{
                .{ .text = "Yes. He said you could use help.", .next_node = 1 },
                .{ .text = "Are you the deaconess?", .next_node = 2 },
            },
        },
        .{
            .speaker = "Anna",
            .text = "Indeed I can. Helena, a widow in the residential lane, was promised oil for her lamps. It has not arrived. Will you look into it?",
            .choices = &.{
                .{ .text = "Of course. Where should I start?", .next_node = 3 },
                .{ .text = "Who was supposed to deliver it?", .next_node = 4 },
            },
        },
        .{
            .speaker = "Anna",
            .text = "I am. I organize the charitable work of this parish. There is always more need than hands. Speaking of which...",
            .next_node = 1,
        },
        .{
            .speaker = "Anna",
            .text = "Helena's house is north, in the residential lane. She will tell you what she knows. Then try Markos at the market -- he deals in oil.",
        },
        .{
            .speaker = "Anna",
            .text = "Markos, the oil merchant in the market street. He is not a bad man, but... business has its pressures. Ask him directly.",
        },
    },
};

pub const markos_dialogue = Dialogue{
    .id = "markos_intro",
    .grants = .spoke_to_markos,
    .nodes = &.{
        .{
            .speaker = "Markos",
            .text = "Welcome, welcome! Looking to buy? I have the finest oil in the quarter.",
            .choices = &.{
                .{ .text = "I am asking about a delivery to Helena.", .next_node = 1 },
                .{ .text = "Just looking around.", .next_node = 3 },
            },
        },
        .{
            .speaker = "Markos",
            .text = "Helena... yes, I know. The delivery was... delayed. Costs have risen, you understand. I had to make difficult choices.",
            .choices = &.{
                .{ .text = "She is a widow. The church trusted you.", .next_node = 2 },
                .{ .text = "What happened to the oil?", .next_node = 2 },
            },
        },
        .{
            .speaker = "Markos",
            .text = "Look, I am not heartless. I will see what I can do. But do not lecture me -- you do not know the pressures of trade.",
        },
        .{
            .speaker = "Markos",
            .text = "Take your time. Quality speaks for itself.",
        },
    },
};

pub const helena_dialogue = Dialogue{
    .id = "helena_intro",
    .grants = .spoke_to_helena,
    .nodes = &.{
        .{
            .speaker = "Helena",
            .text = "Oh... you are from the church? I was not expecting anyone.",
            .choices = &.{
                .{ .text = "Anna sent me. She said oil was promised to you.", .next_node = 1 },
                .{ .text = "How are you, sister?", .next_node = 2 },
            },
        },
        .{
            .speaker = "Helena",
            .text = "Yes. It was to come last week. The lamps are dark, and my daughter is afraid at night. I did not want to complain.",
        },
        .{
            .speaker = "Helena",
            .text = "I manage. God provides. But... the nights are long without light, and my daughter worries.",
            .next_node = 1,
        },
    },
};

pub const stephanos_dialogue = Dialogue{
    .id = "stephanos_intro",
    .grants = .spoke_to_stephanos,
    .nodes = &.{
        .{
            .speaker = "Stephanos",
            .text = "Another catechumen! I thought I was the only one still fumbling through the prayers.",
            .choices = &.{
                .{ .text = "How long have you been preparing?", .next_node = 1 },
                .{ .text = "It is good to meet you.", .next_node = 2 },
            },
        },
        .{
            .speaker = "Stephanos",
            .text = "Three months now. Sometimes I think I understand, and then Father Theophilos asks a question that makes me realize I know nothing. But that is the point, I suppose.",
        },
        .{
            .speaker = "Stephanos",
            .text = "And you. It helps to know someone else is on the same path. If you need anything, I am usually near the courtyard.",
        },
    },
};

pub const diodoros_dialogue = Dialogue{
    .id = "diodoros_intro",
    .grants = .spoke_to_diodoros,
    .nodes = &.{
        .{
            .speaker = "Diodoros",
            .text = "Careful where you step. These crates are heavier than they look.",
            .choices = &.{
                .{ .text = "Do you work the harbor?", .next_node = 1 },
                .{ .text = "Have you seen oil shipments come through?", .next_node = 2 },
            },
        },
        .{
            .speaker = "Diodoros",
            .text = "Loading court, mostly. Everything that comes into this quarter passes through here. I see more than people think.",
        },
        .{
            .speaker = "Diodoros",
            .text = "Oil? Plenty comes through. Whether it all ends up where it is supposed to... that is another question. Talk to Markos if you want answers.",
        },
    },
};

// NPC placements in the Portico Quarter
// requires = .none means always visible; otherwise the flag must be set
pub const district_npcs = [_]Npc{
    .{ .name = "Father Theophilos", .x = 1050, .y = 700, .dialogue = &theophilos_dialogue, .requires = .none },
    .{ .name = "Anna", .x = 1150, .y = 850, .dialogue = &anna_dialogue, .requires = .spoke_to_theophilos },
    .{ .name = "Stephanos", .x = 980, .y = 780, .dialogue = &stephanos_dialogue, .requires = .spoke_to_theophilos },
    .{ .name = "Markos", .x = 450, .y = 540, .dialogue = &markos_dialogue, .requires = .spoke_to_anna },
    .{ .name = "Helena", .x = 1100, .y = 310, .dialogue = &helena_dialogue, .requires = .spoke_to_anna },
    .{ .name = "Diodoros", .x = 1600, .y = 1200, .dialogue = &diodoros_dialogue, .requires = .spoke_to_anna },
};

// --- Tests ---

const expect = std.testing.expect;

test "npc distance calculation" {
    const npc = Npc{ .name = "Test", .x = 100, .y = 100, .dialogue = &theophilos_dialogue };
    const dist = npc.distanceTo(100, 100);
    try std.testing.expectApproxEqAbs(dist, 0.0, 0.01);
}

test "npc interaction radius" {
    const npc = Npc{ .name = "Test", .x = 100, .y = 100, .dialogue = &theophilos_dialogue };
    try expect(npc.canInteract(120, 110));
    try expect(!npc.canInteract(300, 300));
}

test "npc not visible without required flag" {
    const flags = Flags{};
    const npc = Npc{ .name = "Anna", .x = 100, .y = 100, .dialogue = &anna_dialogue, .requires = .spoke_to_theophilos };
    try expect(!npc.isVisible(&flags));
}

test "npc visible after flag granted" {
    var flags = Flags{};
    flags.grant(.spoke_to_theophilos);
    const npc = Npc{ .name = "Anna", .x = 100, .y = 100, .dialogue = &anna_dialogue, .requires = .spoke_to_theophilos };
    try expect(npc.isVisible(&flags));
}

test "npc with no requirement always visible" {
    const flags = Flags{};
    const npc = Npc{ .name = "Test", .x = 100, .y = 100, .dialogue = &theophilos_dialogue, .requires = .none };
    try expect(npc.isVisible(&flags));
}

test "find interactable skips hidden npcs" {
    var flags = Flags{};
    // Only Theophilos should be findable at start
    const idx = findInteractable(&district_npcs, 1050, 700, &flags);
    try expect(idx != null);
    try std.testing.expectEqualStrings("Father Theophilos", district_npcs[idx.?].name);

    // Anna is nearby but hidden
    const anna_idx = findInteractable(&district_npcs, 1150, 850, &flags);
    try expect(anna_idx == null);

    // After speaking to Theophilos, Anna appears
    flags.grant(.spoke_to_theophilos);
    const anna_idx2 = findInteractable(&district_npcs, 1150, 850, &flags);
    try expect(anna_idx2 != null);
    try std.testing.expectEqualStrings("Anna", district_npcs[anna_idx2.?].name);
}
