// Pure game state machine — no raylib dependency.

const std = @import("std");
const Player = @import("player.zig").Player;
const Bounds = @import("player.zig").Bounds;
const Input = @import("player.zig").Input;
const clamp = @import("player.zig").clamp;
const DialogueState = @import("dialogue.zig").DialogueState;
const Flag = @import("flags.zig").Flag;
const Flags = @import("flags.zig").Flags;
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
    }

    pub fn inDialogue(self: *const GameState) bool {
        return self.dialogue.active;
    }

    pub fn tryInteract(self: *GameState) void {
        if (self.dialogue.active) return;
        if (self.nearby_npc) |idx| {
            self.dialogue.start(npc_mod.district_npcs[idx].dialogue);
        }
    }

    pub fn advanceDialogue(self: *GameState) void {
        const flag = self.dialogue.advance();
        if (flag != .none) {
            self.flags.grant(flag);
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

    // Serializable snapshot for save/load
    pub const SaveData = struct {
        player_x: f32,
        player_y: f32,
        player_facing: u8,
        camera_x: f32,
        camera_y: f32,
        flags: [32]bool = [_]bool{false} ** 32,
        version: u32 = 2,
    };

    pub fn toSaveData(self: *const GameState) SaveData {
        return .{
            .player_x = self.player.x,
            .player_y = self.player.y,
            .player_facing = @intFromEnum(self.player.facing),
            .camera_x = self.camera_x,
            .camera_y = self.camera_y,
            .flags = self.flags.set,
        };
    }

    pub fn fromSaveData(data: SaveData) GameState {
        return .{
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
    }
};

// --- Tests ---

const expect = std.testing.expect;
const expectApprox = std.testing.expectApproxEqAbs;

test "initial state is title" {
    const gs = GameState.init();
    try expect(gs.scene == .title);
}

test "startGame transitions to gameplay" {
    var gs = GameState.init();
    gs.startGame();
    try expect(gs.scene == .gameplay);
    try expectApprox(gs.player.x, 1050.0, 0.01);
    try expectApprox(gs.player.y, 750.0, 0.01);
}

test "pause transitions to paused" {
    var gs = GameState.init();
    gs.startGame();
    gs.pause();
    try expect(gs.scene == .paused);
}

test "pause only works from gameplay" {
    var gs = GameState.init();
    gs.pause();
    try expect(gs.scene == .title);
}

test "resume returns to gameplay" {
    var gs = GameState.init();
    gs.startGame();
    gs.pause();
    gs.applyMenuAction(.resume_game);
    try expect(gs.scene == .gameplay);
}

test "quit_to_title returns to title" {
    var gs = GameState.init();
    gs.startGame();
    gs.pause();
    gs.applyMenuAction(.quit_to_title);
    try expect(gs.scene == .title);
}

test "gameplay updates player position" {
    var gs = GameState.init();
    gs.startGame();
    const start_x = gs.player.x;
    gs.updateGameplay(.{ .right = true }, 0.5);
    try expect(gs.player.x > start_x);
}

test "camera follows player" {
    var gs = GameState.init();
    gs.startGame();
    gs.updateGameplay(.{ .right = true }, 0.5);
    try expectApprox(gs.camera_x, gs.player.centerX() - screen_width / 2.0, 1.0);
}

test "save/load roundtrip preserves state and flags" {
    var gs = GameState.init();
    gs.startGame();
    gs.flags.grant(.spoke_to_theophilos);
    gs.updateGameplay(.{ .right = true, .down = true }, 1.0);

    const save = gs.toSaveData();
    const loaded = GameState.fromSaveData(save);

    try expectApprox(loaded.player.x, gs.player.x, 0.01);
    try expectApprox(loaded.player.y, gs.player.y, 0.01);
    try expect(loaded.player.facing == gs.player.facing);
    try expect(loaded.scene == .gameplay);
    try expect(loaded.flags.has(.spoke_to_theophilos));
    try expect(!loaded.flags.has(.spoke_to_anna));
}

test "dialogue completion grants flag" {
    var gs = GameState.init();
    gs.startGame();
    gs.dialogue.start(&npc_mod.theophilos_dialogue);
    try expect(!gs.flags.has(.spoke_to_theophilos));

    // Pick first choice, then advance to end
    gs.dialogue.selected_choice = 0;
    gs.advanceDialogue(); // node 0 -> 1
    gs.advanceDialogue(); // node 1 is terminal -> grants flag

    try expect(gs.flags.has(.spoke_to_theophilos));
    try expect(!gs.dialogue.active);
}

test "only theophilos visible at start" {
    var gs = GameState.init();
    gs.startGame();
    // Near Theophilos
    gs.player = Player.init(1050, 700);
    gs.updateGameplay(.{}, 0);
    try expect(gs.nearby_npc != null);

    // Near Anna's position but she's hidden
    gs.player = Player.init(1150, 850);
    gs.updateGameplay(.{}, 0);
    try expect(gs.nearby_npc == null);

    // After speaking to Theophilos, Anna appears
    gs.flags.grant(.spoke_to_theophilos);
    gs.updateGameplay(.{}, 0);
    try expect(gs.nearby_npc != null);
}
