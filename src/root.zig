const std = @import("std");
const r = @import("raylib.zig");
const World = @import("World.zig");
const WorldCell = @import("WorldCell.zig");
const WorldCoordinates = @import("WorldCoordinates.zig");

const WorldChange = struct {
    coords: WorldCoordinates,
    new_cell_type: WorldCell.WorldCellType,
};

var world: World = undefined;
var change_count: u32 = 0;
var changes: [1024]WorldChange = [1]WorldChange{undefined} ** 1024;

pub fn init() void {
    world = World{};
    world.init();
}

pub fn tick() void {
    change_count = 0;

    var i: u32 = 0;
    while (i < World.WORLD_LENGTH) : (i += 1) {
        const cell = world.cells[i];
        tickConways(cell, WorldCoordinates.fromCellIndex(i));
    }

    var c: u32 = 0;
    while (c < change_count) : (c += 1) {
        const change = changes[c];
        world.setValueAt(change.coords, change.new_cell_type);
    }
}

fn tickConways(value: WorldCell, coords: WorldCoordinates) void {
    switch(value.cell_type) {
        .Conways => {
            const aliveNeighbors = world.countNeighbors(coords, .Conways);
            if (aliveNeighbors < 2) {
                addChange(.{ .coords = coords, .new_cell_type = .Empty });
            } else if (aliveNeighbors > 3) {
                addChange(.{ .coords = coords, .new_cell_type = .Empty });
            }
        },
        .Empty => {
            const aliveNeighbors = world.countNeighbors(coords, .Conways);
            if (aliveNeighbors == 3) {
                addChange(.{ .coords = coords, .new_cell_type = .Conways });
            }
        },
    }
}

fn addChange(change: WorldChange) void {
    changes[change_count] = change;
    change_count += 1;
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
