const std = @import("std");

const WorldCoordinates = @import("WorldCoordinates.zig"); 
const WorldCell = @import("WorldCell.zig");
const WorldCellType = WorldCell.WorldCellType;

pub const WIDTH: i32 = 75;
pub const HEIGHT: i32 = 75;
pub const WORLD_LENGTH: u32 = WIDTH * HEIGHT;

cells: [WORLD_LENGTH]WorldCell = [1]WorldCell{WorldCell{}} ** WORLD_LENGTH,

const World = @This();

pub fn init(self: *World) void {
    const center = WorldCoordinates{ .x = WIDTH / 2, .y = HEIGHT / 2 };

    self.setTypeAt(center, .Conways);
    self.setTypeAt(center.up(), .Conways);
    self.setTypeAt(center.left(), .Conways);
    self.setTypeAt(center.down(), .Conways);
    self.setTypeAt(center.down().right(), .Conways);
}

pub fn getTypeAt(self: *World, coords: WorldCoordinates) WorldCellType {
    return self.cells[coords.toCellIndex()].cell_type;
}

pub fn setTypeAt(self: *World, coords: WorldCoordinates, value: WorldCellType) void {
    self.cells[coords.toCellIndex()].cell_type = value;
}

pub fn countNeighbors(self: *World, coords: WorldCoordinates, cell_type: WorldCellType) u32 {
    var count: u32 = 0;

    var x: i32 = -1;
    while (x <= 1) : (x += 1) {
        var y: i32 = -1;
        while (y <= 1) : (y += 1) {
            if (!(x == 0 and y == 0)) {
                if (self.getTypeAt(coords.plus(.{ .x = x, .y = y })) == cell_type) {
                    count += 1;
                }
            }
        }
    }

    return count;
}
