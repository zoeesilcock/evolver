const std = @import("std");

const World = @import("World.zig");

x: u32 = 0,
y: u32 = 0,

const WorldCoordinates = @This();

pub fn fromCellIndex(index: u32) WorldCoordinates {
    var result: WorldCoordinates = .{};

    result.y = @divFloor(index, World.WIDTH);
    result.x = index - (result.y * World.WIDTH); 

    return result;
}

pub fn toCellIndex(self: WorldCoordinates) u32 {
    const cell_index = self.x + self.y * World.WIDTH;
    std.debug.assert(cell_index < World.WORLD_LENGTH);
    return cell_index;
}

fn wrapValue(value: i32, max: i32) u32 {
    var result = value;
    if (result > max - 1) {
        result = result - max;
    }
    if (result < 0) {
        result = max + result;
    }
    return @intCast(result);
}

fn plusWrap(a: u32, b: u32, max: i32) u32 {
    return wrapValue(@as(i32, @intCast(a)) + @as(i32, @intCast(b)), max);
}

fn minusWrap(a: u32, b: u32, max: i32) u32 {
    return wrapValue(@as(i32, @intCast(a)) - @as(i32, @intCast(b)), max);
}

pub fn plus(self: WorldCoordinates, other: WorldCoordinates) WorldCoordinates {
    return WorldCoordinates{
        .x = plusWrap(self.x, other.x, World.WIDTH),
        .y = plusWrap(self.y, other.y, World.HEIGHT),
    };
}

pub fn minus(self: WorldCoordinates, other: WorldCoordinates) WorldCoordinates {
    return WorldCoordinates{
        .x = minusWrap(self.x, other.x, World.WIDTH),
        .y = minusWrap(self.y, other.y, World.HEIGHT),
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
