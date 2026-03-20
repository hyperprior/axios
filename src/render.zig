// All raylib rendering lives here. Game logic modules have no raylib dependency.

const c = @import("raylib.zig").c;
const GameState = @import("game_state.zig").GameState;
const gs_mod = @import("game_state.zig");
const player_mod = @import("player.zig");

const screen_width: c_int = @intFromFloat(gs_mod.screen_width);
const screen_height: c_int = @intFromFloat(gs_mod.screen_height);
const world_w: c_int = @intFromFloat(gs_mod.world_w);
const world_h: c_int = @intFromFloat(gs_mod.world_h);

// Colors
const gold = c.Color{ .r = 212, .g = 175, .b = 55, .a = 255 };
const warm_stone = c.Color{ .r = 180, .g = 165, .b = 140, .a = 255 };
const muted = c.Color{ .r = 140, .g = 130, .b = 120, .a = 255 };
const bg = c.Color{ .r = 20, .g = 18, .b = 24, .a = 255 };
const overlay = c.Color{ .r = 20, .g = 18, .b = 24, .a = 160 };
const ground = c.Color{ .r = 58, .g = 50, .b = 40, .a = 255 };
const stone_wall = c.Color{ .r = 120, .g = 110, .b = 95, .a = 255 };
const church_color = c.Color{ .r = 160, .g = 130, .b = 80, .a = 255 };
const market_color = c.Color{ .r = 140, .g = 100, .b = 60, .a = 255 };
const house_color = c.Color{ .r = 130, .g = 115, .b = 95, .a = 255 };
const water_color = c.Color{ .r = 40, .g = 70, .b = 100, .a = 255 };
const path_color = c.Color{ .r = 90, .g = 78, .b = 65, .a = 255 };
const label_color = c.Color{ .r = 200, .g = 185, .b = 160, .a = 200 };
const hud_color = c.Color{ .r = 212, .g = 175, .b = 55, .a = 255 };
const hud_bg = c.Color{ .r = 20, .g = 18, .b = 24, .a = 180 };
const player_body = c.Color{ .r = 180, .g = 140, .b = 100, .a = 255 };
const player_indicator = c.Color{ .r = 240, .g = 220, .b = 180, .a = 255 };

const Zone = struct { x: f32, y: f32, w: f32, h: f32, color: c.Color, label: [*:0]const u8 };
const Path = struct { x: f32, y: f32, w: f32, h: f32 };

const zones = [_]Zone{
    .{ .x = 900, .y = 600, .w = 400, .h = 350, .color = church_color, .label = "Church of the Holy Wisdom" },
    .{ .x = 200, .y = 500, .w = 600, .h = 120, .color = market_color, .label = "Market Street" },
    .{ .x = 700, .y = 200, .w = 180, .h = 350, .color = house_color, .label = "Residential Lane" },
    .{ .x = 1050, .y = 250, .w = 200, .h = 160, .color = house_color, .label = "Helena's House" },
    .{ .x = 100, .y = 1400, .w = 2200, .h = 300, .color = water_color, .label = "Harbor" },
    .{ .x = 1500, .y = 1100, .w = 350, .h = 250, .color = market_color, .label = "Loading Court" },
};

const paths = [_]Path{
    .{ .x = 800, .y = 540, .w = 100, .h = 60 },
    .{ .x = 850, .y = 550, .w = 60, .h = 100 },
    .{ .x = 850, .y = 200, .w = 60, .h = 1200 },
    .{ .x = 200, .y = 1350, .w = 1650, .h = 50 },
    .{ .x = 1300, .y = 800, .w = 250, .h = 50 },
};

fn i(f: f32) c_int {
    return @intFromFloat(f);
}

pub fn drawFrame(gs: *const GameState, has_save: bool) void {
    c.ClearBackground(bg);
    switch (gs.scene) {
        .title => drawTitle(has_save),
        .gameplay => drawGameplay(gs),
        .paused => {
            drawGameplay(gs);
            drawPause();
        },
    }
}

fn drawTitle(has_save: bool) void {
    const title = "AXIOS";
    const title_size = 60;
    const title_width = c.MeasureText(title, title_size);
    c.DrawText(title, @divTrunc(screen_width - title_width, 2), screen_height / 3, title_size, gold);

    const subtitle = "Constantinople, 4th Century AD";
    const sub_size = 24;
    const sub_width = c.MeasureText(subtitle, sub_size);
    c.DrawText(subtitle, @divTrunc(screen_width - sub_width, 2), screen_height / 3 + 80, sub_size, warm_stone);

    const prompt = "Press ENTER to begin";
    const prompt_size = 18;
    const prompt_width = c.MeasureText(prompt, prompt_size);
    c.DrawText(prompt, @divTrunc(screen_width - prompt_width, 2), i(@as(f32, @floatFromInt(screen_height)) * 0.7), prompt_size, muted);

    if (has_save) {
        const load_text = "Press L to load saved game";
        const load_width = c.MeasureText(load_text, prompt_size);
        c.DrawText(load_text, @divTrunc(screen_width - load_width, 2), i(@as(f32, @floatFromInt(screen_height)) * 0.7) + 28, prompt_size, muted);
    }
}

fn drawGameplay(gs: *const GameState) void {
    const cx = gs.camera_x;
    const cy = gs.camera_y;

    // Ground
    c.DrawRectangle(i(-cx), i(-cy), world_w, world_h, ground);

    // Paths
    for (paths) |p| {
        c.DrawRectangle(i(p.x - cx), i(p.y - cy), i(p.w), i(p.h), path_color);
    }

    // Zones
    for (zones) |z| {
        c.DrawRectangle(i(z.x - cx), i(z.y - cy), i(z.w), i(z.h), z.color);
        c.DrawRectangleLines(i(z.x - cx), i(z.y - cy), i(z.w), i(z.h), stone_wall);
        c.DrawText(z.label, i(z.x - cx + 10), i(z.y - cy + 10), 16, label_color);
    }

    // Player
    drawPlayer(&gs.player, cx, cy);

    // HUD
    c.DrawRectangle(0, 0, screen_width, 36, hud_bg);
    c.DrawText("The Portico Quarter", 12, 8, 20, hud_color);
    c.DrawText("WASD: Move  ESC: Pause  F5: Save", screen_width - 340, 10, 16, label_color);
}

fn drawPlayer(p: *const player_mod.Player, cx: f32, cy: f32) void {
    const size: c_int = @intFromFloat(player_mod.player_size);
    const sx = i(p.x - cx);
    const sy = i(p.y - cy);

    c.DrawRectangle(sx, sy, size, size, player_body);

    const pcx = sx + @divTrunc(size, 2);
    const pcy = sy + @divTrunc(size, 2);
    const ind: c_int = 4;
    switch (p.facing) {
        .north => c.DrawRectangle(pcx - @divTrunc(ind, 2), sy, ind, ind, player_indicator),
        .south => c.DrawRectangle(pcx - @divTrunc(ind, 2), sy + size - ind, ind, ind, player_indicator),
        .west => c.DrawRectangle(sx, pcy - @divTrunc(ind, 2), ind, ind, player_indicator),
        .east => c.DrawRectangle(sx + size - ind, pcy - @divTrunc(ind, 2), ind, ind, player_indicator),
    }
}

fn drawPause() void {
    c.DrawRectangle(0, 0, screen_width, screen_height, overlay);

    const title = "PAUSED";
    const title_size = 40;
    const title_width = c.MeasureText(title, title_size);
    c.DrawText(title, @divTrunc(screen_width - title_width, 2), screen_height / 3, title_size, gold);

    const resume_text = "[ESC/R] Resume    [Q] Quit to Title";
    const resume_size = 18;
    const resume_width = c.MeasureText(resume_text, resume_size);
    c.DrawText(resume_text, @divTrunc(screen_width - resume_width, 2), screen_height / 3 + 60, resume_size, warm_stone);
}
