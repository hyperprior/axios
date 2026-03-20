// Save/load game state to disk.
// Uses a simple binary format since Zig 0.16's JSON API requires Io.Writer.

const std = @import("std");
const GameState = @import("game_state.zig").GameState;

const c_io = @cImport({
    @cInclude("stdio.h");
    @cInclude("sys/stat.h");
    @cInclude("unistd.h");
});

const save_dir = "saves";
const save_file = save_dir ++ "/slot1.sav";
const magic: u32 = 0x4158494F; // "AXIO"

pub const SaveError = error{
    WriteFailed,
};

pub const LoadError = error{
    FileNotFound,
    ReadFailed,
    InvalidFormat,
};

pub fn save(gs: *const GameState) SaveError!void {
    const data = gs.toSaveData();

    _ = c_io.mkdir(save_dir, 0o755);

    const file = c_io.fopen(save_file, "wb") orelse return error.WriteFailed;
    defer _ = c_io.fclose(file);

    // Write magic + version + data
    const header = [_]u32{ magic, data.version };
    if (c_io.fwrite(&header, @sizeOf(@TypeOf(header)), 1, file) != 1) return error.WriteFailed;

    const floats = [_]f32{ data.player_x, data.player_y, data.camera_x, data.camera_y };
    if (c_io.fwrite(&floats, @sizeOf(@TypeOf(floats)), 1, file) != 1) return error.WriteFailed;

    const facing = [_]u8{data.player_facing};
    if (c_io.fwrite(&facing, 1, 1, file) != 1) return error.WriteFailed;

    // Write flags
    if (c_io.fwrite(&data.flags, @sizeOf(@TypeOf(data.flags)), 1, file) != 1) return error.WriteFailed;
}

pub fn load() LoadError!GameState {
    const file = c_io.fopen(save_file, "rb") orelse return error.FileNotFound;
    defer _ = c_io.fclose(file);

    var header: [2]u32 = undefined;
    if (c_io.fread(&header, @sizeOf(@TypeOf(header)), 1, file) != 1) return error.ReadFailed;
    if (header[0] != magic) return error.InvalidFormat;

    var floats: [4]f32 = undefined;
    if (c_io.fread(&floats, @sizeOf(@TypeOf(floats)), 1, file) != 1) return error.ReadFailed;

    var facing: [1]u8 = undefined;
    if (c_io.fread(&facing, 1, 1, file) != 1) return error.ReadFailed;

    var flags_data: [32]bool = [_]bool{false} ** 32;
    if (header[1] >= 2) {
        // Version 2+ includes flags
        if (c_io.fread(&flags_data, @sizeOf(@TypeOf(flags_data)), 1, file) != 1) return error.ReadFailed;
    }

    return GameState.fromSaveData(.{
        .version = header[1],
        .player_x = floats[0],
        .player_y = floats[1],
        .camera_x = floats[2],
        .camera_y = floats[3],
        .player_facing = facing[0],
        .flags = flags_data,
    });
}

pub fn hasSave() bool {
    const file = c_io.fopen(save_file, "rb");
    if (file) |f| {
        _ = c_io.fclose(f);
        return true;
    }
    return false;
}

pub fn deleteSave() void {
    _ = c_io.remove(save_file);
}

// --- Tests ---

const expect = std.testing.expect;
const expectApprox = std.testing.expectApproxEqAbs;

test "save and load roundtrip" {
    var gs = GameState.init();
    gs.startGame();
    gs.updateGameplay(.{ .right = true, .down = true }, 1.0);

    try save(&gs);

    const loaded = try load();
    try expectApprox(loaded.player.x, gs.player.x, 0.01);
    try expectApprox(loaded.player.y, gs.player.y, 0.01);
    try expect(loaded.player.facing == gs.player.facing);
    try expectApprox(loaded.camera_x, gs.camera_x, 0.01);
    try expectApprox(loaded.camera_y, gs.camera_y, 0.01);

    deleteSave();
    _ = c_io.rmdir(save_dir);
}

test "load nonexistent file returns error" {
    deleteSave();
    const result = load();
    try expect(result == error.FileNotFound);
}

test "hasSave returns false when no save" {
    deleteSave();
    try expect(!hasSave());
}

test "hasSave returns true after save" {
    var gs = GameState.init();
    gs.startGame();
    try save(&gs);
    try expect(hasSave());

    deleteSave();
    _ = c_io.rmdir(save_dir);
}
