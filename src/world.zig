const std = @import("std");
const WorldCell = @import("WorldCell.zig");
const WorldCellType = WorldCell.WorldCellType;

pub const WIDTH = 100;
pub const HEIGHT = 75;
pub const WORLD_LENGTH = WIDTH * HEIGHT;

cells: [WORLD_LENGTH]WorldCell = [1]WorldCell{WorldCell{ .cell_type = .Empty }} ** WORLD_LENGTH,

const World = @This();

pub fn init(self: *World) void {
    const x = WIDTH / 2;
    const y = HEIGHT / 2;

    self.setValueAt(x, y, .Conways);
    self.setValueAt(x, y - 1, .Conways);
    self.setValueAt(x - 1, y, .Conways);
    self.setValueAt(x, y + 1, .Conways);
    self.setValueAt(x + 1, y + 1, .Conways);
}

fn cellIndexFromCoordinates(x: u32, y: u32) u32 {
    const cell_index = x + y * WIDTH;
    std.debug.assert(cell_index < WORLD_LENGTH);
    return cell_index;
}

pub fn getValueAt(self: *World, x: u32, y: u32) WorldCellType {
    return self.cells[cellIndexFromCoordinates(x, y)].cell_type;
}

pub fn setValueAt(self: *World, x: u32, y: u32, value: WorldCellType) void {
    self.cells[cellIndexFromCoordinates(x, y)].cell_type = value;
}
