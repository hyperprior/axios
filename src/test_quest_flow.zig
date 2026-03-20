// End-to-end test: plays through both quests to verify the full chain works.

const std = @import("std");
const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;
const GameState = @import("game_state.zig").GameState;
const Player = @import("player.zig").Player;
const npc_mod = @import("npc.zig");

fn talkTo(gs: *GameState, npc_name: []const u8) void {
    // Move player to NPC and interact
    for (npc_mod.district_npcs, 0..) |npc, i| {
        if (std.mem.eql(u8, npc.name, npc_name)) {
            gs.player = Player.init(npc.x, npc.y);
            gs.updateGameplay(.{}, 0);
            if (gs.nearby_npc) |idx| {
                if (idx == i) {
                    gs.tryInteract();
                    return;
                }
            }
        }
    }
}

fn advanceToEnd(gs: *GameState) void {
    var safety: u32 = 0;
    while (gs.dialogue.active and safety < 50) : (safety += 1) {
        gs.advanceDialogue();
    }
}

fn advanceAndChoose(gs: *GameState, choice: u8) void {
    gs.dialogue.selected_choice = choice;
    gs.advanceDialogue();
}

test "full First Instruction quest flow" {
    var gs = GameState.init();
    gs.startGame();

    // 1. Talk to Theophilos — starts quest
    talkTo(&gs, "Father Theophilos");
    try expect(gs.dialogue.active);
    advanceAndChoose(&gs, 0); // "Father, I am ready to serve"
    advanceToEnd(&gs);
    try expect(gs.flags.has(.spoke_to_theophilos));
    try expect(gs.quests.getConst(.first_instruction).isActive());

    // 2. Talk to Anna — learn about Helena, advance quest
    talkTo(&gs, "Anna");
    try expect(gs.dialogue.active);
    advanceAndChoose(&gs, 0); // "Yes. He said you could use help"
    advanceAndChoose(&gs, 0); // "Of course. Where should I start?"
    advanceToEnd(&gs);
    try expect(gs.flags.has(.spoke_to_anna));
    try expect(gs.quests.getConst(.widows_oil).isActive());

    // 3. Talk to Stephanos — advance to return stage
    talkTo(&gs, "Stephanos");
    try expect(gs.dialogue.active);
    advanceAndChoose(&gs, 0); // "How long have you been preparing?"
    advanceToEnd(&gs);
    try expect(gs.flags.has(.spoke_to_stephanos));
    try expect(gs.quests.getConst(.first_instruction).stage == .fi_return_to_theophilos);

    // 4. Return to Theophilos — complete First Instruction
    talkTo(&gs, "Father Theophilos");
    try expect(gs.dialogue.active);
    advanceAndChoose(&gs, 0); // "There is real need here"
    advanceToEnd(&gs);
    try expect(gs.quests.getConst(.first_instruction).isComplete());
    try expect(gs.flags.has(.first_instruction_done));
}

test "full Widow's Oil quest flow — confrontation path" {
    var gs = GameState.init();
    gs.startGame();

    // Setup: complete First Instruction quickly
    gs.flags.grant(.spoke_to_theophilos);
    gs.flags.grant(.spoke_to_anna);
    gs.flags.grant(.spoke_to_stephanos);
    gs.flags.grant(.first_instruction_done);
    gs.quests.start(.first_instruction);
    gs.quests.advance(.first_instruction, .fi_complete);
    gs.quests.start(.widows_oil);

    // 1. Visit Helena
    talkTo(&gs, "Helena");
    try expect(gs.dialogue.active);
    advanceAndChoose(&gs, 0); // "Anna sent me"
    advanceToEnd(&gs);
    try expect(gs.flags.has(.spoke_to_helena));
    try expect(gs.quests.getConst(.widows_oil).stage == .wo_investigate_markos);

    // 2. Talk to Markos
    talkTo(&gs, "Markos");
    try expect(gs.dialogue.active);
    advanceAndChoose(&gs, 0); // "I am asking about Helena"
    advanceAndChoose(&gs, 0); // "She is a widow. The church trusted you"
    advanceToEnd(&gs);
    try expect(gs.flags.has(.spoke_to_markos));
    try expect(gs.quests.getConst(.widows_oil).stage == .wo_talk_to_diodoros);

    // 3. Talk to Diodoros
    talkTo(&gs, "Diodoros");
    try expect(gs.dialogue.active);
    advanceAndChoose(&gs, 0); // "Markos said you handle deliveries"
    advanceToEnd(&gs);
    try expect(gs.flags.has(.spoke_to_diodoros));
    try expect(gs.quests.getConst(.widows_oil).stage == .wo_decide_resolution);

    // 4. Return to Markos — confront
    talkTo(&gs, "Markos");
    try expect(gs.dialogue.active);
    advanceAndChoose(&gs, 0); // "You sold Helena's oil"
    advanceToEnd(&gs);
    try expect(gs.flags.has(.oil_confronted_markos));
    try expect(gs.quests.getConst(.widows_oil).isComplete());

    // 5. Visit Helena — resolution
    talkTo(&gs, "Helena");
    try expect(gs.dialogue.active);
    advanceAndChoose(&gs, 0); // "God provides"
    advanceToEnd(&gs);
    try expect(gs.flags.has(.oil_resolved));

    // 6. Virtue check — courage should be high from confrontation
    try expect(gs.formation.get(.courage) > 0);
}

test "full Widow's Oil quest flow — mercy path" {
    var gs = GameState.init();
    gs.startGame();

    // Setup
    gs.flags.grant(.spoke_to_theophilos);
    gs.flags.grant(.spoke_to_anna);
    gs.flags.grant(.spoke_to_stephanos);
    gs.flags.grant(.first_instruction_done);
    gs.quests.start(.widows_oil);

    // Helena
    talkTo(&gs, "Helena");
    advanceAndChoose(&gs, 1); // "How are you, sister?" (more mercy)
    advanceToEnd(&gs);

    // Markos
    talkTo(&gs, "Markos");
    advanceAndChoose(&gs, 0); // Ask about Helena
    advanceAndChoose(&gs, 1); // "She has no light at night" (mercy)
    advanceToEnd(&gs);

    // Diodoros
    talkTo(&gs, "Diodoros");
    advanceAndChoose(&gs, 0);
    advanceToEnd(&gs);

    // Return to Markos — appeal to conscience
    talkTo(&gs, "Markos");
    advanceAndChoose(&gs, 1); // "I am not here to condemn you"
    advanceToEnd(&gs);
    try expect(gs.flags.has(.oil_appealed_markos));
    try expect(gs.quests.getConst(.widows_oil).isComplete());

    // Helena
    talkTo(&gs, "Helena");
    advanceToEnd(&gs);
    try expect(gs.flags.has(.oil_resolved));

    // Mercy should be dominant
    try expect(gs.formation.get(.mercy) > gs.formation.get(.courage));
}
