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

pub fn plus(self: WorldCoordinates, other: WorldCoordinates) WorldCoordinates {
    // TODO: Implement wrap here.
    return WorldCoordinates{
        .x = self.x + other.x,
        .y = self.y + other.y,
    };
}

pub fn minus(self: WorldCoordinates, other: WorldCoordinates) WorldCoordinates {
    // TODO: Implement wrap here.
    return WorldCoordinates{
        .x = self.x - other.x,
        .y = self.y - other.y,
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
