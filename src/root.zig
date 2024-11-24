const std = @import("std");
const r = @import("raylib.zig");
const World = @import("World.zig");
const WorldCoordinates = @import("WorldCoordinates.zig");

var world: World = undefined;

pub fn init() void {
    world = World{};
    world.init();
}

pub fn tick() void {
    var i: u32 = 0;
    while (i < World.WORLD_LENGTH) : (i += 1) {
        const cell = world.cells[i];
        switch(cell.cell_type) {
            .Conways => tickConways(WorldCoordinates.fromCellIndex(i)),
            .Empty => {},
        }
    }
}

fn tickConways(coords: WorldCoordinates) void {
    _ = coords;
}

pub fn getImage() r.Image {
    var image = r.GenImageColor(World.WIDTH, World.HEIGHT, r.BLACK);

    var i: u32 = 0;
    while (i < World.WORLD_LENGTH) : (i += 1) {
        const coords = WorldCoordinates.fromCellIndex(i);
        const color = if (world.getValueAt(coords) == .Empty) r.BLACK else r.WHITE;

        r.ImageDrawPixel(&image, @intCast(coords.x), @intCast(coords.y), color);
    }

    return image;
}
