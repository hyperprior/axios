// NPC data and interaction logic. No raylib dependency.

const std = @import("std");
const Dialogue = @import("dialogue.zig").Dialogue;
const Effect = @import("dialogue.zig").Effect;
const Flag = @import("flags.zig").Flag;
const Flags = @import("flags.zig").Flags;
const QuestStage = @import("quest.zig").QuestStage;
const QuestLog = @import("quest.zig").QuestLog;

const interaction_radius: f32 = 50.0;

pub const DialogueEntry = struct {
    dialogue: *const Dialogue,
    requires_flag: Flag = .none,
    requires_stage: QuestStage = .not_started,
};

pub const Npc = struct {
    name: []const u8,
    x: f32,
    y: f32,
    dialogues: []const DialogueEntry,
    size: f32 = 20,
    requires: Flag = .none,

    pub fn isVisible(self: *const Npc, flags: *const Flags) bool {
        return self.requires == .none or flags.has(self.requires);
    }

    pub fn selectDialogue(self: *const Npc, flags: *const Flags, quest_log: *const QuestLog) ?*const Dialogue {
        // Walk entries in reverse — later entries are more specific
        var i: usize = self.dialogues.len;
        while (i > 0) {
            i -= 1;
            const entry = &self.dialogues[i];
            const flag_ok = entry.requires_flag == .none or flags.has(entry.requires_flag);
            const stage_ok = entry.requires_stage == .not_started or blk: {
                // Check if any quest is at this stage
                for (&quest_log.quests) |*q| {
                    if (q.stage == entry.requires_stage) break :blk true;
                }
                break :blk false;
            };
            if (flag_ok and stage_ok) return entry.dialogue;
        }
        return null;
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

// ============================================================
// Dialogue content
// ============================================================

// --- Father Theophilos ---

pub const theophilos_intro = Dialogue{
    .id = "theophilos_intro",
    .grants = .spoke_to_theophilos,
    .nodes = &.{
        .{
            .speaker = "Father Theophilos",
            .text = "Ah, you have come. The Lord's timing is perfect, as always.",
            .choices = &.{
                .{ .text = "Father, I am ready to serve.", .next_node = 1, .effect = .{ .virtue = .humility, .virtue_amount = 1 } },
                .{ .text = "What would you have me do?", .next_node = 2 },
                .{ .text = "I am still learning my way around.", .next_node = 3, .effect = .{ .virtue = .humility, .virtue_amount = 2 } },
            },
        },
        .{
            .speaker = "Father Theophilos",
            .text = "Good. A willing heart is the beginning of wisdom. Anna in the courtyard needs help today. Speak with her.",
            .effect = .{ .start_quest = .first_instruction },
        },
        .{
            .speaker = "Father Theophilos",
            .text = "Today there are errands to be done and people to be helped. Find Anna -- she will guide you.",
            .effect = .{ .start_quest = .first_instruction },
        },
        .{
            .speaker = "Father Theophilos",
            .text = "That is no shame. Walk the district, speak to the people. But first, find Anna near the courtyard.",
            .effect = .{ .start_quest = .first_instruction },
        },
    },
};

pub const theophilos_after_anna = Dialogue{
    .id = "theophilos_check_in",
    .nodes = &.{
        .{
            .speaker = "Father Theophilos",
            .text = "Have you spoken with Anna? Good. There is much to do in this quarter. Keep your eyes open and your heart ready.",
        },
    },
};

pub const theophilos_return = Dialogue{
    .id = "theophilos_return",
    .grants = .first_instruction_done,
    .nodes = &.{
        .{
            .speaker = "Father Theophilos",
            .text = "You have met the people of this quarter. What have you seen?",
            .choices = &.{
                .{ .text = "There is real need here. Helena has no oil for her lamps.", .next_node = 1, .effect = .{ .virtue = .mercy, .virtue_amount = 2 } },
                .{ .text = "Everyone seems to have their own worries.", .next_node = 2, .effect = .{ .virtue = .truth, .virtue_amount = 1 } },
            },
        },
        .{
            .speaker = "Father Theophilos",
            .text = "Yes. The poor are often invisible to those who are busy. You have seen well. Now go -- help Helena. That is where your service begins.",
            .effect = .{ .advance_quest = .first_instruction, .quest_stage = .fi_complete },
        },
        .{
            .speaker = "Father Theophilos",
            .text = "True. But a catechumen must learn to see beneath the surface. Go to Helena, see her need directly. That is where faith becomes action.",
            .effect = .{ .advance_quest = .first_instruction, .quest_stage = .fi_complete },
        },
    },
};

pub const theophilos_during_oil = Dialogue{
    .id = "theophilos_during_oil",
    .nodes = &.{
        .{
            .speaker = "Father Theophilos",
            .text = "You are learning the life of this quarter. Keep going. The truth is worth pursuing, even when it is uncomfortable.",
        },
    },
};

pub const theophilos_oil_resolved = Dialogue{
    .id = "theophilos_oil_resolved",
    .nodes = &.{
        .{
            .speaker = "Father Theophilos",
            .text = "I have heard what you did for Helena. Tell me -- what did you learn?",
            .choices = &.{
                .{ .text = "That mercy requires courage, not just sympathy.", .next_node = 1, .effect = .{ .virtue = .courage, .virtue_amount = 2 } },
                .{ .text = "That the poor are easy to forget.", .next_node = 2, .effect = .{ .virtue = .mercy, .virtue_amount = 2 } },
                .{ .text = "That truth is more complicated than I expected.", .next_node = 3, .effect = .{ .virtue = .truth, .virtue_amount = 2 } },
            },
        },
        .{
            .speaker = "Father Theophilos",
            .text = "Yes. To speak truth to power is not cruelty -- it is love. You are growing, child. The evening vigil approaches. Let us prepare.",
        },
        .{
            .speaker = "Father Theophilos",
            .text = "And yet God does not forget them. You remembered Helena when others did not. That is the beginning of a faithful life.",
        },
        .{
            .speaker = "Father Theophilos",
            .text = "It always is. The world is not divided neatly into saints and sinners. Markos is not evil -- he is pressured. Discernment is knowing the difference.",
        },
    },
};

// --- Anna ---

pub const anna_intro = Dialogue{
    .id = "anna_intro",
    .grants = .spoke_to_anna,
    .nodes = &.{
        .{
            .speaker = "Anna",
            .text = "Peace be with you. You must be the catechumen Father Theophilos spoke of.",
            .choices = &.{
                .{ .text = "Yes. He said you could use help.", .next_node = 1, .effect = .{ .virtue = .humility, .virtue_amount = 1 } },
                .{ .text = "Are you the deaconess?", .next_node = 2 },
            },
        },
        .{
            .speaker = "Anna",
            .text = "Indeed. Helena, a widow in the residential lane, was promised oil for her lamps. It has not arrived. Will you look into it?",
            .choices = &.{
                .{ .text = "Of course. Where should I start?", .next_node = 3, .effect = .{ .virtue = .mercy, .virtue_amount = 1 } },
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
            .text = "Helena's house is north, in the lane. Speak with her first. Then try Markos at the market -- he deals in oil. And find Stephanos too -- he may have heard something.",
            .effect = .{ .advance_quest = .first_instruction, .quest_stage = .fi_talk_to_stephanos, .start_quest = .widows_oil },
        },
        .{
            .speaker = "Anna",
            .text = "Markos, the oil merchant. He is not a bad man, but business has its pressures. Ask him directly. Also speak to Stephanos nearby.",
            .effect = .{ .advance_quest = .first_instruction, .quest_stage = .fi_talk_to_stephanos, .start_quest = .widows_oil },
        },
    },
};

pub const anna_waiting = Dialogue{
    .id = "anna_waiting",
    .nodes = &.{
        .{
            .speaker = "Anna",
            .text = "Have you visited Helena yet? Her house is north in the residential lane. And do not forget Stephanos -- he is usually near the church.",
        },
    },
};

pub const anna_oil_resolved = Dialogue{
    .id = "anna_oil_resolved",
    .nodes = &.{
        .{
            .speaker = "Anna",
            .text = "Helena told me what happened. Thank you. It is not always easy to do right in a world of compromises.",
            .next_node = 1,
        },
        .{
            .speaker = "Anna",
            .text = "Speak with Father Theophilos. He will want to hear what you have learned. The evening vigil is approaching.",
        },
    },
};

// --- Stephanos ---

pub const stephanos_intro = Dialogue{
    .id = "stephanos_intro",
    .grants = .spoke_to_stephanos,
    .nodes = &.{
        .{
            .speaker = "Stephanos",
            .text = "Another catechumen! I thought I was the only one still fumbling through the prayers.",
            .choices = &.{
                .{ .text = "How long have you been preparing?", .next_node = 1 },
                .{ .text = "Have you heard anything about Helena's oil?", .next_node = 2, .effect = .{ .virtue = .truth, .virtue_amount = 1 } },
            },
        },
        .{
            .speaker = "Stephanos",
            .text = "Three months now. It helps to know someone else is on the same path. You should return to Father Theophilos when you are ready.",
            .effect = .{ .advance_quest = .first_instruction, .quest_stage = .fi_return_to_theophilos },
        },
        .{
            .speaker = "Stephanos",
            .text = "Helena? I heard Markos had trouble with a shipment. Or maybe it was the costs. People talk, but no one says the same thing. You should ask him directly.",
            .effect = .{ .advance_quest = .first_instruction, .quest_stage = .fi_return_to_theophilos },
        },
    },
};

// --- Helena ---

pub const helena_intro = Dialogue{
    .id = "helena_intro",
    .grants = .spoke_to_helena,
    .nodes = &.{
        .{
            .speaker = "Helena",
            .text = "Oh... you are from the church? I was not expecting anyone.",
            .choices = &.{
                .{ .text = "Anna sent me. She said oil was promised to you.", .next_node = 1, .effect = .{ .virtue = .mercy, .virtue_amount = 1 } },
                .{ .text = "How are you, sister?", .next_node = 2, .effect = .{ .virtue = .mercy, .virtue_amount = 2 } },
            },
        },
        .{
            .speaker = "Helena",
            .text = "Yes. It was to come last week. The lamps are dark, and my daughter is afraid at night. I did not want to complain.",
            .effect = .{ .advance_quest = .widows_oil, .quest_stage = .wo_investigate_markos },
        },
        .{
            .speaker = "Helena",
            .text = "I manage. God provides. But the nights are long without light, and my daughter worries. The oil was promised but never came.",
            .next_node = 1,
        },
    },
};

// --- Markos ---

pub const markos_intro = Dialogue{
    .id = "markos_intro",
    .grants = .spoke_to_markos,
    .nodes = &.{
        .{
            .speaker = "Markos",
            .text = "Welcome! Looking to buy? I have the finest oil in the quarter.",
            .choices = &.{
                .{ .text = "I am asking about a delivery to Helena.", .next_node = 1, .effect = .{ .virtue = .courage, .virtue_amount = 1 } },
                .{ .text = "Just looking around.", .next_node = 4 },
            },
        },
        .{
            .speaker = "Markos",
            .text = "Helena... yes, I know. The delivery was delayed. Costs have risen, you understand. I had to make difficult choices.",
            .choices = &.{
                .{ .text = "She is a widow. The church trusted you with this.", .next_node = 2, .effect = .{ .virtue = .courage, .virtue_amount = 2 } },
                .{ .text = "I understand. But she has no light at night.", .next_node = 3, .effect = .{ .virtue = .mercy, .virtue_amount = 2 } },
            },
        },
        .{
            .speaker = "Markos",
            .text = "Do not lecture me. I am not heartless. Fine -- I will see what I can do. But speak to Diodoros at the loading court. He handles the deliveries.",
            .effect = .{ .advance_quest = .widows_oil, .quest_stage = .wo_talk_to_diodoros, .grant_flag = .knows_about_oil },
        },
        .{
            .speaker = "Markos",
            .text = "You are right. She should not suffer for my problems. I will arrange something. Ask Diodoros at the loading court about the delivery.",
            .effect = .{ .advance_quest = .widows_oil, .quest_stage = .wo_talk_to_diodoros, .grant_flag = .knows_about_oil },
        },
        .{
            .speaker = "Markos",
            .text = "Take your time. Quality speaks for itself.",
        },
    },
};

pub const markos_resolution = Dialogue{
    .id = "markos_resolution",
    .nodes = &.{
        .{
            .speaker = "Markos",
            .text = "You again. I can see it in your face -- Diodoros told you.",
            .choices = &.{
                .{ .text = "You sold Helena's oil to someone else. A widow's oil.", .next_node = 1, .effect = .{ .virtue = .courage, .virtue_amount = 3 } },
                .{ .text = "Markos, I know what happened. But I am not here to condemn you.", .next_node = 2, .effect = .{ .virtue = .mercy, .virtue_amount = 3 } },
                .{ .text = "I will cover the cost myself. Just send the oil to Helena.", .next_node = 3, .effect = .{ .virtue = .faithfulness, .virtue_amount = 3 } },
            },
        },
        .{
            // Confrontation path
            .speaker = "Markos",
            .text = "... You are right. I knew it was wrong. I told myself it was business, but... a widow. Her daughter. I will send the oil tonight. And I will speak to Father Theophilos myself.",
            .effect = .{ .grant_flag = .oil_confronted_markos, .advance_quest = .widows_oil, .quest_stage = .wo_complete },
        },
        .{
            // Appeal path
            .speaker = "Markos",
            .text = "You... are kinder than I deserve. I let the money make the decision for me. I will send the oil. And perhaps... I will come to the vigil tonight.",
            .effect = .{ .grant_flag = .oil_appealed_markos, .advance_quest = .widows_oil, .quest_stage = .wo_complete },
        },
        .{
            // Cover the gap path
            .speaker = "Markos",
            .text = "No -- no. I will not let you pay for my failure. Keep your money. I will send the oil myself. You shame me with your generosity, catechumen.",
            .effect = .{ .grant_flag = .oil_covered_gap, .advance_quest = .widows_oil, .quest_stage = .wo_complete },
        },
    },
};

pub const markos_after = Dialogue{
    .id = "markos_after",
    .nodes = &.{
        .{
            .speaker = "Markos",
            .text = "The oil has been sent. I... thank you. It was easier to look away than I realized.",
        },
    },
};

// --- Helena outcome ---

pub const helena_resolved = Dialogue{
    .id = "helena_resolved",
    .grants = .oil_resolved,
    .nodes = &.{
        .{
            .speaker = "Helena",
            .text = "The oil came! My daughter laughed when I lit the lamp. Thank you -- thank the church. I had almost stopped hoping.",
            .choices = &.{
                .{ .text = "God provides, through His people.", .next_node = 1, .effect = .{ .virtue = .faithfulness, .virtue_amount = 2 } },
                .{ .text = "You should never have had to wait so long.", .next_node = 2, .effect = .{ .virtue = .truth, .virtue_amount = 2 } },
            },
        },
        .{
            .speaker = "Helena",
            .text = "He does. And today He sent you. Will you come to the vigil tonight? I would like my daughter to meet the one who helped us.",
        },
        .{
            .speaker = "Helena",
            .text = "Perhaps. But it came. That is what matters tonight. Will you be at the vigil? I want to light a candle for you.",
        },
    },
};

// --- Diodoros ---

pub const diodoros_intro = Dialogue{
    .id = "diodoros_intro",
    .grants = .spoke_to_diodoros,
    .nodes = &.{
        .{
            .speaker = "Diodoros",
            .text = "Careful where you step. These crates are heavier than they look.",
            .choices = &.{
                .{ .text = "Markos said you handle oil deliveries.", .next_node = 1, .effect = .{ .virtue = .truth, .virtue_amount = 1 } },
                .{ .text = "Do you work the harbor?", .next_node = 2 },
            },
        },
        .{
            .speaker = "Diodoros",
            .text = "The oil for the widow? It came in. But Markos redirected it to a paying customer. He told me not to say anything. The oil exists -- it was just... reprioritized.",
            .effect = .{ .advance_quest = .widows_oil, .quest_stage = .wo_decide_resolution },
        },
        .{
            .speaker = "Diodoros",
            .text = "Loading court, mostly. Everything that comes into this quarter passes through here. I see more than people think.",
            .next_node = 1,
        },
    },
};

pub const diodoros_after = Dialogue{
    .id = "diodoros_after",
    .nodes = &.{
        .{
            .speaker = "Diodoros",
            .text = "I told you what I know. The rest is between you, Markos, and the Almighty.",
        },
    },
};

// ============================================================
// NPC placements
// ============================================================

pub const district_npcs = [_]Npc{
    .{
        .name = "Father Theophilos",
        .x = 1050,
        .y = 700,
        .requires = .none,
        .dialogues = &.{
            .{ .dialogue = &theophilos_intro },
            .{ .dialogue = &theophilos_after_anna, .requires_flag = .spoke_to_anna },
            .{ .dialogue = &theophilos_return, .requires_stage = .fi_return_to_theophilos },
            .{ .dialogue = &theophilos_during_oil, .requires_flag = .first_instruction_done },
            .{ .dialogue = &theophilos_oil_resolved, .requires_flag = .oil_resolved },
        },
    },
    .{
        .name = "Anna",
        .x = 1150,
        .y = 850,
        .requires = .spoke_to_theophilos,
        .dialogues = &.{
            .{ .dialogue = &anna_intro },
            .{ .dialogue = &anna_waiting, .requires_flag = .spoke_to_anna },
            .{ .dialogue = &anna_oil_resolved, .requires_flag = .oil_resolved },
        },
    },
    .{
        .name = "Stephanos",
        .x = 980,
        .y = 780,
        .requires = .spoke_to_theophilos,
        .dialogues = &.{
            .{ .dialogue = &stephanos_intro },
        },
    },
    .{
        .name = "Markos",
        .x = 450,
        .y = 540,
        .requires = .spoke_to_anna,
        .dialogues = &.{
            .{ .dialogue = &markos_intro },
            .{ .dialogue = &markos_resolution, .requires_stage = .wo_decide_resolution },
            .{ .dialogue = &markos_after, .requires_stage = .wo_complete },
        },
    },
    .{
        .name = "Helena",
        .x = 1100,
        .y = 310,
        .requires = .spoke_to_anna,
        .dialogues = &.{
            .{ .dialogue = &helena_intro },
            .{ .dialogue = &helena_resolved, .requires_stage = .wo_complete },
        },
    },
    .{
        .name = "Diodoros",
        .x = 1600,
        .y = 1200,
        .requires = .spoke_to_anna,
        .dialogues = &.{
            .{ .dialogue = &diodoros_intro },
            .{ .dialogue = &diodoros_after, .requires_flag = .spoke_to_diodoros },
        },
    },
};

// --- Tests ---

const expect = std.testing.expect;

test "npc visibility with flags" {
    const flags = Flags{};
    try expect(district_npcs[0].isVisible(&flags)); // Theophilos always
    try expect(!district_npcs[1].isVisible(&flags)); // Anna hidden

    var flags2 = Flags{};
    flags2.grant(.spoke_to_theophilos);
    try expect(district_npcs[1].isVisible(&flags2)); // Anna visible
}

test "dialogue selection picks most specific" {
    var flags = Flags{};
    const log = QuestLog{};

    // Before speaking: get intro
    const d1 = district_npcs[0].selectDialogue(&flags, &log).?;
    try std.testing.expectEqualStrings("theophilos_intro", d1.id);

    // After speaking to Anna: get check-in
    flags.grant(.spoke_to_anna);
    const d2 = district_npcs[0].selectDialogue(&flags, &log).?;
    try std.testing.expectEqualStrings("theophilos_check_in", d2.id);
}

test "dialogue selection with quest stage" {
    var flags = Flags{};
    flags.grant(.spoke_to_anna);
    var log = QuestLog{};
    log.start(.first_instruction);
    log.advance(.first_instruction, .fi_return_to_theophilos);

    const d = district_npcs[0].selectDialogue(&flags, &log).?;
    try std.testing.expectEqualStrings("theophilos_return", d.id);
}

test "find interactable skips hidden" {
    const flags = Flags{};
    const idx = findInteractable(&district_npcs, 1050, 700, &flags);
    try expect(idx != null);
    try std.testing.expectEqualStrings("Father Theophilos", district_npcs[idx.?].name);
}
