// Texture loading and management. This is the only module besides render.zig
// that touches raylib for asset loading.

const c = @import("raylib.zig").c;

pub const Textures = struct {
    // Tiles
    ground: c.Texture2D = undefined,
    path: c.Texture2D = undefined,
    church: c.Texture2D = undefined,
    market: c.Texture2D = undefined,
    house: c.Texture2D = undefined,
    water: c.Texture2D = undefined,
    wall: c.Texture2D = undefined,

    // Sprites
    player: c.Texture2D = undefined,
    theophilos: c.Texture2D = undefined,
    anna: c.Texture2D = undefined,
    stephanos: c.Texture2D = undefined,
    markos: c.Texture2D = undefined,
    helena: c.Texture2D = undefined,
    diodoros: c.Texture2D = undefined,
    ambient_male: c.Texture2D = undefined,
    ambient_female: c.Texture2D = undefined,
    ambient_elder: c.Texture2D = undefined,
    ambient_child: c.Texture2D = undefined,
    ambient_worker: c.Texture2D = undefined,

    loaded: bool = false,

    pub fn load(self: *Textures) void {
        self.ground = c.LoadTexture("assets/tiles/ground.png");
        self.path = c.LoadTexture("assets/tiles/path.png");
        self.church = c.LoadTexture("assets/tiles/church.png");
        self.market = c.LoadTexture("assets/tiles/market.png");
        self.house = c.LoadTexture("assets/tiles/house.png");
        self.water = c.LoadTexture("assets/tiles/water.png");
        self.wall = c.LoadTexture("assets/tiles/wall.png");

        self.player = c.LoadTexture("assets/sprites/player.png");
        self.theophilos = c.LoadTexture("assets/sprites/theophilos.png");
        self.anna = c.LoadTexture("assets/sprites/anna.png");
        self.stephanos = c.LoadTexture("assets/sprites/stephanos.png");
        self.markos = c.LoadTexture("assets/sprites/markos.png");
        self.helena = c.LoadTexture("assets/sprites/helena.png");
        self.diodoros = c.LoadTexture("assets/sprites/diodoros.png");
        self.ambient_male = c.LoadTexture("assets/sprites/ambient_male.png");
        self.ambient_female = c.LoadTexture("assets/sprites/ambient_female.png");
        self.ambient_elder = c.LoadTexture("assets/sprites/ambient_elder.png");
        self.ambient_child = c.LoadTexture("assets/sprites/ambient_child.png");
        self.ambient_worker = c.LoadTexture("assets/sprites/ambient_worker.png");

        self.loaded = true;
    }

    pub fn unload(self: *Textures) void {
        if (!self.loaded) return;
        c.UnloadTexture(self.ground);
        c.UnloadTexture(self.path);
        c.UnloadTexture(self.church);
        c.UnloadTexture(self.market);
        c.UnloadTexture(self.house);
        c.UnloadTexture(self.water);
        c.UnloadTexture(self.wall);
        c.UnloadTexture(self.player);
        c.UnloadTexture(self.theophilos);
        c.UnloadTexture(self.anna);
        c.UnloadTexture(self.stephanos);
        c.UnloadTexture(self.markos);
        c.UnloadTexture(self.helena);
        c.UnloadTexture(self.diodoros);
        c.UnloadTexture(self.ambient_male);
        c.UnloadTexture(self.ambient_female);
        c.UnloadTexture(self.ambient_elder);
        c.UnloadTexture(self.ambient_child);
        c.UnloadTexture(self.ambient_worker);
        self.loaded = false;
    }

    pub fn npcTexture(self: *const Textures, name: []const u8) c.Texture2D {
        const std = @import("std");
        if (std.mem.eql(u8, name, "Father Theophilos")) return self.theophilos;
        if (std.mem.eql(u8, name, "Anna")) return self.anna;
        if (std.mem.eql(u8, name, "Stephanos")) return self.stephanos;
        if (std.mem.eql(u8, name, "Markos")) return self.markos;
        if (std.mem.eql(u8, name, "Helena")) return self.helena;
        if (std.mem.eql(u8, name, "Diodoros")) return self.diodoros;
        return self.ambient_male; // fallback
    }

    pub fn ambientTexture(self: *const Textures, name: []const u8) c.Texture2D {
        const std = @import("std");
        if (std.mem.eql(u8, name, "Child")) return self.ambient_child;
        if (std.mem.eql(u8, name, "Boy with Bread")) return self.ambient_child;
        if (std.mem.eql(u8, name, "Elderly Man")) return self.ambient_elder;
        if (std.mem.eql(u8, name, "Seated Elder")) return self.ambient_elder;
        if (std.mem.eql(u8, name, "Laborer")) return self.ambient_worker;
        if (std.mem.eql(u8, name, "Dockworker")) return self.ambient_worker;
        if (std.mem.eql(u8, name, "Woman at Basin")) return self.ambient_female;
        if (std.mem.eql(u8, name, "Sweeping Woman")) return self.ambient_female;
        if (std.mem.eql(u8, name, "Neighbor Woman")) return self.ambient_female;
        if (std.mem.eql(u8, name, "Young Mother")) return self.ambient_female;
        if (std.mem.eql(u8, name, "Lamp Lighter")) return self.ambient_worker;
        if (std.mem.eql(u8, name, "Chanter")) return self.ambient_elder;
        if (std.mem.eql(u8, name, "Acolyte")) return self.ambient_male;
        return self.ambient_male;
    }
};
