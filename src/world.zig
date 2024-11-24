const std = @import("std");

pub const WIDTH = 200;
pub const HEIGHT = 150;
pub const WORLD_LENGTH = WIDTH * HEIGHT;

cells: [WORLD_LENGTH]u32 = [1]u32{0} ** WORLD_LENGTH,

const World = @This();

pub fn init(self: *World) void {
    for (0..WIDTH) |i| {
        const x: u32 = @intCast(i);
        const y: u32 = @min(HEIGHT - 1, x);
        self.setValueAt(x, y, 1);
    }
}

fn cellIndexFromCoordinates(x: u32, y: u32) u32 {
    const cell_index = x + y * WIDTH;
    std.debug.assert(cell_index < WORLD_LENGTH);
    return cell_index;
}

pub fn getValueAt(self: *World, x: u32, y: u32) u32 {
    return self.cells[cellIndexFromCoordinates(x, y)];
}

pub fn setValueAt(self: *World, x: u32, y: u32, value: u32) void {
    self.cells[cellIndexFromCoordinates(x, y)] = value;
}
