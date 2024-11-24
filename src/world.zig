const std = @import("std");

const WorldCoordinates = @import("WorldCoordinates.zig"); 
const WorldCell = @import("WorldCell.zig");
const WorldCellType = WorldCell.WorldCellType;

pub const WIDTH = 100;
pub const HEIGHT = 75;
pub const WORLD_LENGTH = WIDTH * HEIGHT;

cells: [WORLD_LENGTH]WorldCell = [1]WorldCell{WorldCell{ .cell_type = .Empty }} ** WORLD_LENGTH,

const World = @This();

pub fn init(self: *World) void {
    const center = WorldCoordinates{ .x = WIDTH / 2, .y = HEIGHT / 2 };

    self.setValueAt(center, .Conways);
    self.setValueAt(center.up(), .Conways);
    self.setValueAt(center.left(), .Conways);
    self.setValueAt(center.down(), .Conways);
    self.setValueAt(center.down().right(), .Conways);
}

pub fn getValueAt(self: *World, coords: WorldCoordinates) WorldCellType {
    return self.cells[coords.toCellIndex()].cell_type;
}

pub fn setValueAt(self: *World, coords: WorldCoordinates, value: WorldCellType) void {
    self.cells[coords.toCellIndex()].cell_type = value;
}

pub fn countNeighbors(self: *World, coords: WorldCoordinates, cell_type: WorldCellType) u32 {
    var count: u32 = 0;

    if (self.getValueAt(coords.up().left()) == cell_type) {
        count += 1;
    }
    if (self.getValueAt(coords.up()) == cell_type) {
        count += 1;
    }
    if (self.getValueAt(coords.up().right()) == cell_type) {
        count += 1;
    }
    if (self.getValueAt(coords.left()) == cell_type) {
        count += 1;
    }
    if (self.getValueAt(coords.right()) == cell_type) {
        count += 1;
    }
    if (self.getValueAt(coords.down().left()) == cell_type) {
        count += 1;
    }
    if (self.getValueAt(coords.down()) == cell_type) {
        count += 1;
    }
    if (self.getValueAt(coords.down().right()) == cell_type) {
        count += 1;
    }

    return count;
}
