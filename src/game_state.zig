// Pure game state machine — no raylib dependency.

const std = @import("std");
const Player = @import("player.zig").Player;
const Bounds = @import("player.zig").Bounds;
const Input = @import("player.zig").Input;
const clamp = @import("player.zig").clamp;
const DialogueState = @import("dialogue.zig").DialogueState;
const Effect = @import("dialogue.zig").Effect;
const Flag = @import("flags.zig").Flag;
const Flags = @import("flags.zig").Flags;
const QuestLog = @import("quest.zig").QuestLog;
const Formation = @import("formation.zig").Formation;
const npc_mod = @import("npc.zig");

pub const screen_width: f32 = 1280;
pub const screen_height: f32 = 720;
pub const world_w: f32 = 2400;
pub const world_h: f32 = 1800;
pub const world_bounds = Bounds{ .x = 0, .y = 0, .w = world_w, .h = world_h };

pub const Scene = enum {
    title,
    gameplay,
    paused,
};

pub const MenuAction = enum {
    none,
    resume_game,
    quit_to_title,
};

pub const GameState = struct {
    scene: Scene = .title,
    player: Player = Player.init(1050, 750),
    camera_x: f32 = 0,
    camera_y: f32 = 0,
    dialogue: DialogueState = .{},
    nearby_npc: ?usize = null,
    flags: Flags = .{},
    quests: QuestLog = .{},
    formation: Formation = .{},

    pub fn init() GameState {
        return .{};
    }

    pub fn startGame(self: *GameState) void {
        self.scene = .gameplay;
        self.player = Player.init(1050, 750);
        self.camera_x = 0;
        self.camera_y = 0;
        self.dialogue = .{};
        self.nearby_npc = null;
        self.flags = .{};
        self.quests = .{};
        self.formation = .{};
    }

    pub fn inDialogue(self: *const GameState) bool {
        return self.dialogue.active;
    }

    pub fn tryInteract(self: *GameState) void {
        if (self.dialogue.active) return;
        if (self.nearby_npc) |idx| {
            const npc = &npc_mod.district_npcs[idx];
            if (npc.selectDialogue(&self.flags, &self.quests)) |d| {
                self.dialogue.start(d);
                self.applyEffect(self.dialogue.pending_effect);
            }
        }
    }

    pub fn advanceDialogue(self: *GameState) void {
        const flag = self.dialogue.advance();
        if (flag != .none) {
            self.flags.grant(flag);
        }
        self.applyEffect(self.dialogue.pending_effect);
    }

    fn applyEffect(self: *GameState, effect: Effect) void {
        if (effect.grant_flag != .none) {
            self.flags.grant(effect.grant_flag);
        }
        if (effect.start_quest) |qid| {
            self.quests.start(qid);
        }
        if (effect.advance_quest) |qid| {
            if (effect.quest_stage != .not_started) {
                self.quests.advance(qid, effect.quest_stage);
            }
        }
        if (effect.virtue) |v| {
            self.formation.add(v, effect.virtue_amount);
        }
    }

    pub fn updateGameplay(self: *GameState, input: Input, dt: f32) void {
        if (!self.dialogue.active) {
            self.player.update(input, dt, world_bounds);
        }

        self.nearby_npc = npc_mod.findInteractable(
            &npc_mod.district_npcs,
            self.player.centerX(),
            self.player.centerY(),
            &self.flags,
        );

        self.camera_x = self.player.centerX() - screen_width / 2.0;
        self.camera_y = self.player.centerY() - screen_height / 2.0;
        self.camera_x = clamp(self.camera_x, 0, world_w - screen_width);
        self.camera_y = clamp(self.camera_y, 0, world_h - screen_height);
    }

    pub fn pause(self: *GameState) void {
        if (self.scene == .gameplay) {
            self.scene = .paused;
        }
    }

    pub fn applyMenuAction(self: *GameState, action: MenuAction) void {
        switch (action) {
            .none => {},
            .resume_game => {
                if (self.scene == .paused) self.scene = .gameplay;
            },
            .quit_to_title => {
                self.scene = .title;
            },
        }
    }

    pub const SaveData = struct {
        player_x: f32,
        player_y: f32,
        player_facing: u8,
        camera_x: f32,
        camera_y: f32,
        flags: [32]bool = [_]bool{false} ** 32,
        quest_stages: [3]u8 = [_]u8{0} ** 3,
        formation: [5]i8 = [_]i8{0} ** 5,
        version: u32 = 3,
    };

    pub fn toSaveData(self: *const GameState) SaveData {
        var quest_stages: [3]u8 = undefined;
        for (self.quests.quests, 0..) |q, i| {
            quest_stages[i] = @intFromEnum(q.stage);
        }
        return .{
            .player_x = self.player.x,
            .player_y = self.player.y,
            .player_facing = @intFromEnum(self.player.facing),
            .camera_x = self.camera_x,
            .camera_y = self.camera_y,
            .flags = self.flags.set,
            .quest_stages = quest_stages,
            .formation = self.formation.values,
        };
    }

    pub fn fromSaveData(data: SaveData) GameState {
        var gs = GameState{
            .scene = .gameplay,
            .player = .{
                .x = data.player_x,
                .y = data.player_y,
                .facing = @enumFromInt(data.player_facing),
            },
            .camera_x = data.camera_x,
            .camera_y = data.camera_y,
            .flags = .{ .set = data.flags },
        };
        if (data.version >= 3) {
            for (data.quest_stages, 0..) |stage, i| {
                gs.quests.quests[i].stage = @enumFromInt(stage);
            }
            gs.formation.values = data.formation;
        }
        return gs;
    }
};

// --- Tests ---

const expect = std.testing.expect;
const expectApprox = std.testing.expectApproxEqAbs;

test "initial state is title" {
    const gs = GameState.init();
    try expect(gs.scene == .title);
}

test "startGame resets everything" {
    var gs = GameState.init();
    gs.startGame();
    try expect(gs.scene == .gameplay);
    try expect(!gs.flags.has(.spoke_to_theophilos));
    try expect(gs.quests.activeObjective() == null);
    try expect(gs.formation.get(.mercy) == 0);
}

test "dialogue effect starts quest" {
    var gs = GameState.init();
    gs.startGame();
    gs.applyEffect(.{ .start_quest = .first_instruction });
    try expect(gs.quests.getConst(.first_instruction).isActive());
}

test "dialogue effect advances quest" {
    var gs = GameState.init();
    gs.startGame();
    gs.quests.start(.first_instruction);
    gs.applyEffect(.{ .advance_quest = .first_instruction, .quest_stage = .fi_talk_to_stephanos });
    try expect(gs.quests.getConst(.first_instruction).stage == .fi_talk_to_stephanos);
}

test "dialogue effect grants virtue" {
    var gs = GameState.init();
    gs.startGame();
    gs.applyEffect(.{ .virtue = .mercy, .virtue_amount = 3 });
    try expect(gs.formation.get(.mercy) == 3);
}

test "save/load roundtrip preserves quests and formation" {
    var gs = GameState.init();
    gs.startGame();
    gs.flags.grant(.spoke_to_theophilos);
    gs.quests.start(.first_instruction);
    gs.formation.add(.mercy, 5);
    gs.updateGameplay(.{ .right = true }, 1.0);

    const save = gs.toSaveData();
    const loaded = GameState.fromSaveData(save);

    try expect(loaded.flags.has(.spoke_to_theophilos));
    try expect(loaded.quests.getConst(.first_instruction).isActive());
    try expect(loaded.formation.get(.mercy) == 5);
}

test "only theophilos visible at start" {
    var gs = GameState.init();
    gs.startGame();
    gs.player = Player.init(1050, 700);
    gs.updateGameplay(.{}, 0);
    try expect(gs.nearby_npc != null);

    gs.player = Player.init(1150, 850);
    gs.updateGameplay(.{}, 0);
    try expect(gs.nearby_npc == null);
}

test "pause and resume" {
    var gs = GameState.init();
    gs.startGame();
    gs.pause();
    try expect(gs.scene == .paused);
    gs.applyMenuAction(.resume_game);
    try expect(gs.scene == .gameplay);
}
