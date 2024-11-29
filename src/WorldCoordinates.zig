const std = @import("std");

const World = @import("World.zig");

x: i32 = 0,
y: i32 = 0,

const WorldCoordinates = @This();

pub fn fromCellIndex(index: u32) WorldCoordinates {
    var result: WorldCoordinates = .{};

    result.y = @divFloor(@as(i32, @intCast(index)), World.WIDTH);
    result.x = @as(i32, @intCast(index)) - (result.y * World.WIDTH); 

    return result;
}

pub fn toCellIndex(self: WorldCoordinates) u32 {
    const cell_index = self.x + self.y * World.WIDTH;
    std.debug.assert(cell_index < World.WORLD_LENGTH);
    return @intCast(cell_index);
}

fn wrapValue(value: i32, max: i32) i32 {
    var result = value;
    if (result > max - 1) {
        result = result - max;
    }
    if (result < 0) {
        result = max + result;
    }
    return @intCast(result);
}

pub fn plus(self: WorldCoordinates, other: WorldCoordinates) WorldCoordinates {
    return WorldCoordinates{
        .x = wrapValue(self.x + other.x, World.WIDTH),
        .y = wrapValue(self.y + other.y, World.HEIGHT),
    };
}

pub fn minus(self: WorldCoordinates, other: WorldCoordinates) WorldCoordinates {
    return WorldCoordinates{
        .x = wrapValue(self.x - other.x, World.WIDTH),
        .y = wrapValue(self.y - other.y, World.HEIGHT),
    };
}

pub fn up(self: WorldCoordinates) WorldCoordinates {
    return self.minus(.{ .y = 1 });
}

pub fn down(self: WorldCoordinates) WorldCoordinates {
    return self.plus(.{ .y = 1 });
}

pub fn left(self: WorldCoordinates) WorldCoordinates {
    return self.minus(.{ .x = 1 });
}

pub fn right(self: WorldCoordinates) WorldCoordinates {
    return self.plus(.{ .x = 1 });
}
