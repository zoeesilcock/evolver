const std = @import("std");
const r = @import("raylib.zig");
const World = @import("World.zig");

var world: World = undefined;

pub fn init() void {
    world = World{};
    world.init();
}

pub fn tick() void {
}

pub fn getImage() r.Image {
    var image = r.GenImageColor(World.WIDTH, World.HEIGHT, r.BLACK);

    var i: u32 = 0;
    while (i < World.WORLD_LENGTH) : (i += 1) {
        const y = @divFloor(i, World.WIDTH);
        const x = i - (y * World.WIDTH);
        const color = if (world.getValueAt(x, y) == 0) r.GRAY else r.WHITE;

        r.ImageDrawPixel(&image, @intCast(x), @intCast(y), color);
    }

    return image;
}
