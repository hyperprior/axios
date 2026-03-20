// Test entry point — only imports pure logic modules (no raylib).
test {
    _ = @import("player.zig");
    _ = @import("game_state.zig");
    _ = @import("save.zig");
    _ = @import("dialogue.zig");
    _ = @import("npc.zig");
    _ = @import("flags.zig");
}
