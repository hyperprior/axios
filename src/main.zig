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

        c.BeginDrawing();
        defer c.EndDrawing();
        render.drawFrame(&gs, save_mod.hasSave());
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
            if ((c.IsKeyDown(c.KEY_LEFT_SHIFT) or c.IsKeyDown(c.KEY_RIGHT_SHIFT)) and c.IsKeyPressed(c.KEY_S)) {
                if (save_mod.save(&gs)) {
                    std.log.info("Game saved", .{});
                } else |err| {
                    std.log.err("Save failed: {}", .{err});
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
    const shift_held = c.IsKeyDown(c.KEY_LEFT_SHIFT) or c.IsKeyDown(c.KEY_RIGHT_SHIFT);
    return .{
        .up = c.IsKeyDown(c.KEY_W) or c.IsKeyDown(c.KEY_UP),
        .down = (!shift_held and c.IsKeyDown(c.KEY_S)) or c.IsKeyDown(c.KEY_DOWN),
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
