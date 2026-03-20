// All raylib rendering lives here. Game logic modules have no raylib dependency.

const c = @import("raylib.zig").c;
const GameState = @import("game_state.zig").GameState;
const gs_mod = @import("game_state.zig");
const player_mod = @import("player.zig");
const npc_mod = @import("npc.zig");
const DialogueState = @import("dialogue.zig").DialogueState;
const Flags = @import("flags.zig").Flags;
const journal_mod = @import("journal.zig");
const JournalState = journal_mod.JournalState;
const TimeOfDay = @import("time_of_day.zig").TimeOfDay;
const VigilState = @import("vigil.zig").VigilState;
const ambient_mod = @import("ambient.zig");
const Textures = @import("textures.zig").Textures;

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
const npc_color = c.Color{ .r = 100, .g = 140, .b = 180, .a = 255 };
const npc_highlight = c.Color{ .r = 220, .g = 200, .b = 120, .a = 255 };
const dialogue_bg = c.Color{ .r = 15, .g = 12, .b = 20, .a = 230 };
const dialogue_border = c.Color{ .r = 160, .g = 130, .b = 80, .a = 255 };
const choice_selected = c.Color{ .r = 212, .g = 175, .b = 55, .a = 255 };
const choice_normal = c.Color{ .r = 160, .g = 150, .b = 135, .a = 255 };

const TileType = enum { church, market, house, water };

const Zone = struct { x: f32, y: f32, w: f32, h: f32, tile: TileType, label: [*:0]const u8 };
const Path = struct { x: f32, y: f32, w: f32, h: f32 };

const zones = [_]Zone{
    .{ .x = 900, .y = 600, .w = 400, .h = 350, .tile = .church, .label = "Church of the Holy Wisdom" },
    .{ .x = 200, .y = 500, .w = 600, .h = 120, .tile = .market, .label = "Market Street" },
    .{ .x = 700, .y = 200, .w = 180, .h = 350, .tile = .house, .label = "Residential Lane" },
    .{ .x = 1050, .y = 250, .w = 200, .h = 160, .tile = .house, .label = "Helena's House" },
    .{ .x = 100, .y = 1400, .w = 2200, .h = 300, .tile = .water, .label = "Harbor" },
    .{ .x = 1500, .y = 1100, .w = 350, .h = 250, .tile = .market, .label = "Loading Court" },
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

pub fn drawFrame(gs: *const GameState, has_save: bool, tex: *const Textures) void {
    c.ClearBackground(bg);
    switch (gs.scene) {
        .title => drawTitle(has_save),
        .gameplay => drawGameplay(gs, tex),
        .paused => {
            drawGameplay(gs, tex);
            drawPause();
        },
        .vigil => drawVigil(&gs.vigil),
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

fn drawGameplay(gs: *const GameState, tex: *const Textures) void {
    const cx = gs.camera_x;
    const cy = gs.camera_y;

    const ts: c_int = 32; // tile size
    const tsf: f32 = 32.0;

    // Tiled ground
    const start_tx = @as(c_int, @intFromFloat(cx / tsf));
    const start_ty = @as(c_int, @intFromFloat(cy / tsf));
    const end_tx = start_tx + @divTrunc(screen_width, ts) + 2;
    const end_ty = start_ty + @divTrunc(screen_height, ts) + 2;

    var ty = start_ty;
    while (ty < end_ty) : (ty += 1) {
        var tx = start_tx;
        while (tx < end_tx) : (tx += 1) {
            const px_x = tx * ts - i(cx);
            const px_y = ty * ts - i(cy);
            if (tx >= 0 and ty >= 0 and tx < @divTrunc(world_w, ts) and ty < @divTrunc(world_h, ts)) {
                c.DrawTexture(tex.ground, px_x, px_y, c.WHITE);
            }
        }
    }

    // Tiled paths
    for (paths) |p| {
        const ptx_start = @as(c_int, @intFromFloat(p.x / tsf));
        const pty_start = @as(c_int, @intFromFloat(p.y / tsf));
        const ptx_end = @as(c_int, @intFromFloat((p.x + p.w) / tsf)) + 1;
        const pty_end = @as(c_int, @intFromFloat((p.y + p.h) / tsf)) + 1;
        var pty = pty_start;
        while (pty < pty_end) : (pty += 1) {
            var ptx = ptx_start;
            while (ptx < ptx_end) : (ptx += 1) {
                c.DrawTexture(tex.path, ptx * ts - i(cx), pty * ts - i(cy), c.WHITE);
            }
        }
    }

    // Tiled zones
    for (zones) |z| {
        const ztile = switch (z.tile) {
            .church => tex.church,
            .market => tex.market,
            .house => tex.house,
            .water => tex.water,
        };
        const ztx_start = @as(c_int, @intFromFloat(z.x / tsf));
        const zty_start = @as(c_int, @intFromFloat(z.y / tsf));
        const ztx_end = @as(c_int, @intFromFloat((z.x + z.w) / tsf)) + 1;
        const zty_end = @as(c_int, @intFromFloat((z.y + z.h) / tsf)) + 1;
        var zty = zty_start;
        while (zty < zty_end) : (zty += 1) {
            var ztx = ztx_start;
            while (ztx < ztx_end) : (ztx += 1) {
                c.DrawTexture(ztile, ztx * ts - i(cx), zty * ts - i(cy), c.WHITE);
            }
        }
        // Zone border
        c.DrawRectangleLines(i(z.x - cx), i(z.y - cy), i(z.w), i(z.h), stone_wall);
        c.DrawText(z.label, i(z.x - cx + 10), i(z.y - cy + 10), 16, label_color);
    }

    // NPCs (only draw visible ones)
    for (npc_mod.district_npcs, 0..) |npc, idx| {
        if (!npc.isVisible(&gs.flags)) continue;
        const is_nearby = gs.nearby_npc != null and gs.nearby_npc.? == idx;
        drawNpcSprite(&npc, cx, cy, is_nearby, tex);
    }

    // Ambient NPCs
    for (ambient_mod.district_ambient, 0..) |anpc, idx| {
        if (!anpc.isVisible(&gs.flags, gs.time)) continue;
        const is_nearby = gs.nearby_ambient != null and gs.nearby_ambient.? == idx;
        drawAmbientNpcSprite(&anpc, cx, cy, is_nearby, tex);
    }

    // Player sprite
    drawPlayerSprite(&gs.player, cx, cy, tex);

    // Ambient speech bubble
    if (gs.ambient_talk_timer > 0) {
        if (gs.nearby_ambient) |idx| {
            const anpc = &ambient_mod.district_ambient[idx];
            drawAmbientSpeech(anpc, cx, cy);
        }
    }

    // Interaction prompt
    if (!gs.dialogue.active and gs.ambient_talk_timer <= 0) {
        if (gs.nearby_npc) |idx| {
            const npc = &npc_mod.district_npcs[idx];
            drawInteractPrompt(npc.name);
        } else if (gs.nearby_ambient) |idx| {
            const anpc = &ambient_mod.district_ambient[idx];
            drawInteractPrompt(anpc.name);
        }
    }

    // Time-of-day tint
    const tint = c.Color{ .r = gs.time.tintR(), .g = gs.time.tintG(), .b = gs.time.tintB(), .a = gs.time.tintA() };
    if (tint.a > 0) {
        c.DrawRectangle(0, 0, screen_width, screen_height, tint);
    }

    // HUD
    c.DrawRectangle(0, 0, screen_width, 36, hud_bg);
    c.DrawText("The Portico Quarter", 12, 8, 20, hud_color);

    // Time label
    const time_label = @as([*:0]const u8, @ptrCast(gs.time.label().ptr));
    const time_width = c.MeasureText(time_label, 16);
    c.DrawText(time_label, @divTrunc(screen_width - time_width, 2), 10, 16, warm_stone);

    c.DrawText("WASD  E:Talk  J:Journal  F5:Save", screen_width - 340, 10, 16, label_color);

    // Quest objective
    if (gs.quests.activeObjective()) |obj| {
        const obj_cstr = @as([*:0]const u8, @ptrCast(obj.ptr));
        const obj_width = c.MeasureText(obj_cstr, 16);
        c.DrawRectangle(0, 36, obj_width + 24, 26, hud_bg);
        c.DrawText(obj_cstr, 12, 40, 16, warm_stone);
    }

    // Dialogue box
    if (gs.dialogue.active) {
        drawDialogue(&gs.dialogue);
    }

    // Journal overlay
    if (gs.journal.open) {
        drawJournal(gs);
    }
}

fn drawAmbientNpcSprite(anpc: *const ambient_mod.AmbientNpc, cx: f32, cy: f32, highlight: bool, tex: *const Textures) void {
    const sprite = tex.ambientTexture(anpc.name);
    const sprite_w: c_int = sprite.width;
    const sprite_h: c_int = sprite.height;
    const sx = i(anpc.x - cx) - @divTrunc(sprite_w, 2);
    const sy = i(anpc.y - cy) - sprite_h;

    const tint_color = if (highlight) c.WHITE else c.Color{ .r = 180, .g = 175, .b = 170, .a = 255 };
    c.DrawTexture(sprite, sx, sy, tint_color);

    if (highlight) {
        const name_cstr = @as([*:0]const u8, @ptrCast(anpc.name.ptr));
        const name_width = c.MeasureText(name_cstr, 12);
        c.DrawText(name_cstr, sx + @divTrunc(sprite_w - name_width, 2), sy - 16, 12, label_color);
    }
}

fn drawAmbientSpeech(anpc: *const ambient_mod.AmbientNpc, cx: f32, cy: f32) void {
    const line_cstr = @as([*:0]const u8, @ptrCast(anpc.line.ptr));
    const name_cstr = @as([*:0]const u8, @ptrCast(anpc.name.ptr));

    // Speech bubble above the NPC
    const sx = i(anpc.x - cx);
    const sy = i(anpc.y - anpc.size / 2 - cy) - 50;

    const line_width = c.MeasureText(line_cstr, 14);
    const name_width = c.MeasureText(name_cstr, 12);
    const bubble_w = @max(line_width, name_width) + 16;
    const bx = sx - @divTrunc(bubble_w, 2);

    c.DrawRectangle(bx, sy, bubble_w, 38, hud_bg);
    c.DrawText(name_cstr, bx + 6, sy + 2, 12, gold);
    c.DrawText(line_cstr, bx + 6, sy + 18, 14, warm_stone);
}

fn drawNpcSprite(npc: *const npc_mod.Npc, cx: f32, cy: f32, highlight: bool, tex: *const Textures) void {
    const sprite = tex.npcTexture(npc.name);
    const sprite_w: c_int = sprite.width;
    const sprite_h: c_int = sprite.height;
    const sx = i(npc.x - cx) - @divTrunc(sprite_w, 2);
    const sy = i(npc.y - cy) - sprite_h;

    c.DrawTexture(sprite, sx, sy, c.WHITE);

    // Highlight ring when nearby
    if (highlight) {
        c.DrawRectangleLines(sx - 2, sy - 2, sprite_w + 4, sprite_h + 4, gold);
    }

    // Name above head
    const name_cstr = @as([*:0]const u8, @ptrCast(npc.name.ptr));
    const name_width = c.MeasureText(name_cstr, 14);
    c.DrawText(name_cstr, sx + @divTrunc(sprite_w - name_width, 2), sy - 18, 14, if (highlight) gold else label_color);
}

fn drawInteractPrompt(name: []const u8) void {
    const name_cstr = @as([*:0]const u8, @ptrCast(name.ptr));
    var buf: [64]u8 = undefined;
    const prompt_text = blk: {
        var idx: usize = 0;
        const prefix = "[E] Talk to ";
        for (prefix) |ch| {
            buf[idx] = ch;
            idx += 1;
        }
        for (name) |ch| {
            if (idx >= buf.len - 1) break;
            buf[idx] = ch;
            idx += 1;
        }
        buf[idx] = 0;
        break :blk @as([*:0]const u8, @ptrCast(&buf));
    };
    _ = name_cstr;

    const prompt_width = c.MeasureText(prompt_text, 18);
    const px = @divTrunc(screen_width - prompt_width, 2);
    const py = screen_height - 60;
    c.DrawRectangle(px - 10, py - 5, prompt_width + 20, 28, hud_bg);
    c.DrawText(prompt_text, px, py, 18, gold);
}

fn drawWrappedText(text: [*:0]const u8, x: c_int, y: c_int, font_size: c_int, max_width: c_int, color: c.Color) c_int {
    // Word-wrap text manually and return total height drawn
    const spacing: c_int = 2;
    const line_height = font_size + 4;
    var line_y = y;
    var start: usize = 0;
    var last_space: usize = 0;
    var idx: usize = 0;

    while (text[idx] != 0) : (idx += 1) {
        if (text[idx] == ' ') last_space = idx;

        // Measure from start to current position
        var measure_buf: [512]u8 = undefined;
        const len = idx - start + 1;
        if (len >= measure_buf.len) break;
        for (start..idx + 1, 0..) |si, di| {
            measure_buf[di] = text[si];
        }
        measure_buf[len] = 0;
        const w = c.MeasureText(@ptrCast(&measure_buf), font_size);

        if (w > max_width - spacing) {
            // Wrap at last space
            const break_at = if (last_space > start) last_space else idx;
            var line_buf: [512]u8 = undefined;
            const line_len = break_at - start;
            if (line_len >= line_buf.len) break;
            for (start..break_at, 0..) |si, di| {
                line_buf[di] = text[si];
            }
            line_buf[line_len] = 0;
            c.DrawText(@ptrCast(&line_buf), x, line_y, font_size, color);
            line_y += line_height;

            // Skip the space
            start = break_at;
            if (text[start] == ' ') start += 1;
            last_space = start;
        }
    }

    // Draw remaining text
    if (start < idx) {
        var line_buf: [512]u8 = undefined;
        const line_len = idx - start;
        if (line_len < line_buf.len) {
            for (start..idx, 0..) |si, di| {
                line_buf[di] = text[si];
            }
            line_buf[line_len] = 0;
            c.DrawText(@ptrCast(&line_buf), x, line_y, font_size, color);
            line_y += line_height;
        }
    }

    return line_y - y;
}

fn drawJournal(gs: *const GameState) void {
    // Full-screen overlay
    c.DrawRectangle(0, 0, screen_width, screen_height, c.Color{ .r = 15, .g = 12, .b = 20, .a = 220 });

    const jx = 80;
    const jy = 60;
    const jw = screen_width - 160;
    const jh = screen_height - 120;

    c.DrawRectangle(jx, jy, jw, jh, c.Color{ .r = 20, .g = 18, .b = 24, .a = 255 });
    c.DrawRectangleLinesEx(.{
        .x = @floatFromInt(jx),
        .y = @floatFromInt(jy),
        .width = @floatFromInt(jw),
        .height = @floatFromInt(jh),
    }, 2, dialogue_border);

    // Tab headers
    const tabs = [_][]const u8{ "Quests", "People", "Codex" };
    var tx: c_int = jx + 16;
    for (tabs, 0..) |tab_name, idx| {
        const tab_cstr = @as([*:0]const u8, @ptrCast(tab_name.ptr));
        const is_active = @intFromEnum(gs.journal.tab) == idx;
        const color = if (is_active) gold else muted;
        c.DrawText(tab_cstr, tx, jy + 12, 20, color);
        if (is_active) {
            const tw = c.MeasureText(tab_cstr, 20);
            c.DrawRectangle(tx, jy + 34, tw, 2, gold);
        }
        tx += 120;
    }

    c.DrawText("[A/D] Switch Tab    [J/ESC] Close", jx + jw - 320, jy + 14, 14, muted);

    const content_y: c_int = jy + 50;
    const content_x = jx + 20;
    const content_w = jw - 40;

    switch (gs.journal.tab) {
        .quests => {
            var cy = content_y;
            for (&gs.quests.quests) |*q| {
                if (q.stage == .not_started) continue;
                const name_cstr = @as([*:0]const u8, @ptrCast(q.name.ptr));
                const status_text: [*:0]const u8 = if (q.isComplete()) " (Complete)" else " (Active)";
                const name_color = if (q.isComplete()) muted else gold;
                c.DrawText(name_cstr, content_x, cy, 18, name_color);
                const nw = c.MeasureText(name_cstr, 18);
                c.DrawText(status_text, content_x + nw, cy, 14, muted);
                cy += 24;

                const desc_cstr = @as([*:0]const u8, @ptrCast(q.description.ptr));
                const dh = drawWrappedText(desc_cstr, content_x + 12, cy, 15, content_w - 12, warm_stone);
                cy += dh + 4;

                if (q.currentObjective()) |obj| {
                    const obj_cstr = @as([*:0]const u8, @ptrCast(obj.ptr));
                    c.DrawText(">", content_x + 12, cy, 15, gold);
                    _ = drawWrappedText(obj_cstr, content_x + 28, cy, 15, content_w - 28, label_color);
                    cy += 22;
                }
                cy += 12;
            }
            if (cy == content_y) {
                c.DrawText("No quests yet. Speak to Father Theophilos.", content_x, cy, 16, muted);
            }
        },
        .people => {
            var cy = content_y;
            for (journal_mod.people_entries) |entry| {
                if (!gs.flags.has(entry.requires)) continue;
                const name_cstr = @as([*:0]const u8, @ptrCast(entry.name.ptr));
                c.DrawText(name_cstr, content_x, cy, 18, gold);
                cy += 22;
                const desc_cstr = @as([*:0]const u8, @ptrCast(entry.description.ptr));
                const dh = drawWrappedText(desc_cstr, content_x + 12, cy, 15, content_w - 12, warm_stone);
                cy += dh + 10;
            }
            if (cy == content_y) {
                c.DrawText("You have not met anyone yet.", content_x, cy, 16, muted);
            }
        },
        .codex => {
            var cy = content_y;
            for (journal_mod.codex_entries) |entry| {
                if (!gs.flags.has(entry.requires)) continue;
                const term_cstr = @as([*:0]const u8, @ptrCast(entry.term.ptr));
                c.DrawText(term_cstr, content_x, cy, 18, gold);
                cy += 22;
                const def_cstr = @as([*:0]const u8, @ptrCast(entry.definition.ptr));
                const dh = drawWrappedText(def_cstr, content_x + 12, cy, 15, content_w - 12, warm_stone);
                cy += dh + 10;
            }
            if (cy == content_y) {
                c.DrawText("No entries yet. Explore and speak with people.", content_x, cy, 16, muted);
            }
        },
    }
}

fn drawDialogue(ds: *const DialogueState) void {
    const node = ds.currentNode() orelse return;

    const box_w = screen_width - 80;
    const box_x = 40;
    const pad = 16;
    const text_width = box_w - pad * 2;
    const text_font: c_int = 17;
    const choice_font: c_int = 17;

    // Calculate required height
    const speaker = @as([*:0]const u8, @ptrCast(node.speaker.ptr));
    const text = @as([*:0]const u8, @ptrCast(node.text.ptr));

    var content_h: c_int = 32 + 8; // speaker + gap
    // Estimate text height (measure by drawing offscreen or approximate)
    content_h += measureWrappedHeight(text, text_font, text_width);
    content_h += 12; // gap after text

    if (node.choices.len > 0) {
        for (node.choices) |choice| {
            const choice_text = @as([*:0]const u8, @ptrCast(choice.text.ptr));
            content_h += measureWrappedHeight(choice_text, choice_font, text_width - 28);
            content_h += 4;
        }
    } else {
        content_h += 24; // continue prompt
    }

    content_h += pad;

    // Minimum height
    if (content_h < 120) content_h = 120;

    const box_h = content_h;
    const box_y = screen_height - box_h - 20;

    // Background
    c.DrawRectangle(box_x, box_y, box_w, box_h, dialogue_bg);
    c.DrawRectangleLinesEx(.{
        .x = @floatFromInt(box_x),
        .y = @floatFromInt(box_y),
        .width = @floatFromInt(box_w),
        .height = @floatFromInt(box_h),
    }, 2, dialogue_border);

    // Speaker name
    c.DrawText(speaker, box_x + pad, box_y + 12, 20, gold);

    // Dialogue text (wrapped)
    const text_y = box_y + 40;
    const text_h = drawWrappedText(text, box_x + pad, text_y, text_font, text_width, warm_stone);

    if (node.choices.len > 0) {
        var choice_y = text_y + text_h + 12;
        for (node.choices, 0..) |choice, idx| {
            const is_selected = idx == ds.selected_choice;
            const color = if (is_selected) choice_selected else choice_normal;
            const prefix: [*:0]const u8 = if (is_selected) "> " else "  ";
            const choice_text = @as([*:0]const u8, @ptrCast(choice.text.ptr));

            c.DrawText(prefix, box_x + pad + 4, choice_y, choice_font, color);
            const ch = drawWrappedText(choice_text, box_x + pad + 28, choice_y, choice_font, text_width - 28, color);
            choice_y += ch + 4;
        }
    } else {
        c.DrawText("[ENTER] Continue", box_x + box_w - 180, box_y + box_h - 28, 16, muted);
    }
}

fn measureWrappedHeight(text: [*:0]const u8, font_size: c_int, max_width: c_int) c_int {
    const line_height = font_size + 4;
    var lines: c_int = 1;
    var start: usize = 0;
    var last_space: usize = 0;
    var idx: usize = 0;

    while (text[idx] != 0) : (idx += 1) {
        if (text[idx] == ' ') last_space = idx;

        var measure_buf: [512]u8 = undefined;
        const len = idx - start + 1;
        if (len >= measure_buf.len) break;
        for (start..idx + 1, 0..) |si, di| {
            measure_buf[di] = text[si];
        }
        measure_buf[len] = 0;
        const w = c.MeasureText(@ptrCast(&measure_buf), font_size);

        if (w > max_width - 2) {
            lines += 1;
            const break_at = if (last_space > start) last_space else idx;
            start = break_at;
            if (text[start] == ' ') start += 1;
            last_space = start;
        }
    }

    return lines * line_height;
}

fn drawVigil(vigil: *const VigilState) void {
    // Deep evening background
    c.ClearBackground(c.Color{ .r = 10, .g = 8, .b = 16, .a = 255 });

    const beat = vigil.currentBeat() orelse return;

    const box_w = screen_width - 160;
    const box_x = 80;

    if (beat.speaker.len > 0) {
        // Speaker name
        const speaker_cstr = @as([*:0]const u8, @ptrCast(beat.speaker.ptr));
        const speaker_width = c.MeasureText(speaker_cstr, 22);
        c.DrawText(speaker_cstr, @divTrunc(screen_width - speaker_width, 2), screen_height / 3 - 30, 22, gold);
    }

    // Beat text (centered, wrapped)
    const text_cstr = @as([*:0]const u8, @ptrCast(beat.text.ptr));
    const text_h = measureWrappedHeight(text_cstr, 18, box_w);
    const text_y = @divTrunc(screen_height - text_h, 2);
    _ = drawWrappedText(text_cstr, box_x, text_y, 18, box_w, warm_stone);

    // Continue prompt
    const prompt = "[ENTER] Continue";
    const pw = c.MeasureText(prompt, 16);
    c.DrawText(prompt, @divTrunc(screen_width - pw, 2), screen_height - 60, 16, muted);
}

fn drawPlayerSprite(p: *const player_mod.Player, cx: f32, cy: f32, tex: *const Textures) void {
    const sprite = tex.player;
    const sprite_w: c_int = sprite.width;
    const sprite_h: c_int = sprite.height;
    const sx = i(p.x - cx) - @divTrunc(sprite_w, 2) + @divTrunc(@as(c_int, @intFromFloat(player_mod.player_size)), 2);
    const sy = i(p.y - cy) - sprite_h + @as(c_int, @intFromFloat(player_mod.player_size));

    c.DrawTexture(sprite, sx, sy, c.WHITE);
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
