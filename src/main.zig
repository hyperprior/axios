const std = @import("std");
const Steam = @import("steam.zig").Steam;
const c = @import("raylib.zig").c;
const GameState = @import("game_state.zig").GameState;
const Input = @import("player.zig").Input;
const render = @import("render.zig");
const save_mod = @import("save.zig");

const game_title = "Axios \xe2\x80\x94 Constantinople, 4th Century";

var gs: GameState = GameState.init();
var steam: Steam = undefined;
var save_msg_timer: f32 = 0;
var save_msg: [*:0]const u8 = "";

pub fn main() void {

    steam = Steam.init();
    defer steam.deinit();

    c.InitWindow(1280, 720, game_title);
    defer c.CloseWindow();
    c.SetTargetFPS(60);
    c.SetExitKey(0);

    while (!c.WindowShouldClose()) {
        steam.runCallbacks();

        const dt = c.GetFrameTime();
        update(dt);

        if (save_msg_timer > 0) save_msg_timer -= dt;

        c.BeginDrawing();
        defer c.EndDrawing();
        render.drawFrame(&gs, save_mod.hasSave());

        // Save notification overlay
        if (save_msg_timer > 0) {
            c.DrawText(save_msg, 12, 720 - 30, 18, c.Color{ .r = 212, .g = 175, .b = 55, .a = 255 });
        }
    }
}

fn update(dt: f32) void {
    switch (gs.scene) {
        .title => {
            if (c.IsKeyPressed(c.KEY_ENTER) or c.IsKeyPressed(c.KEY_SPACE)) {
                gs.startGame();
            }
            if (c.IsKeyPressed(c.KEY_L) and save_mod.hasSave()) {
                if (save_mod.load()) |loaded| {
                    gs = loaded;
                } else |_| {}
            }
        },
        .gameplay => {
            gs.updateGameplay(readInput(), dt);

            if (c.IsKeyPressed(c.KEY_ESCAPE)) {
                gs.pause();
            }
            if (c.IsKeyPressed(c.KEY_F5)) {
                if (save_mod.save(&gs)) {
                    save_msg = "Game saved";
                    save_msg_timer = 2.0;
                } else |_| {
                    save_msg = "Save failed!";
                    save_msg_timer = 2.0;
                }
            }
        },
        .paused => {
            if (c.IsKeyPressed(c.KEY_ESCAPE) or c.IsKeyPressed(c.KEY_R)) {
                gs.applyMenuAction(.resume_game);
            }
            if (c.IsKeyPressed(c.KEY_Q)) {
                gs.applyMenuAction(.quit_to_title);
            }
        },
    }
}

fn readInput() Input {
    return .{
        .up = c.IsKeyDown(c.KEY_W) or c.IsKeyDown(c.KEY_UP),
        .down = c.IsKeyDown(c.KEY_S) or c.IsKeyDown(c.KEY_DOWN),
        .left = c.IsKeyDown(c.KEY_A) or c.IsKeyDown(c.KEY_LEFT),
        .right = c.IsKeyDown(c.KEY_D) or c.IsKeyDown(c.KEY_RIGHT),
    };
}

// Pull in tests from all modules
test {
    _ = @import("player.zig");
    _ = @import("game_state.zig");
    _ = @import("save.zig");
}
