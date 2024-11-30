const std = @import("std");
const r = @import("dependencies/raylib.zig");

const UI = @import("UI.zig");
const World = @import("World.zig");
const WorldCell = @import("WorldCell.zig");
const WorldCoordinates = @import("WorldCoordinates.zig");

const TimeProgressState = enum(u32) {
    Stopped,
    Step,
    Running,
};

pub const State = struct {
    allocator: std.mem.Allocator,
    time_state: TimeProgressState = .Stopped,
    world: World = World{},
    change_count: u32 = 0,
    changes: [1024]WorldChange = [1]WorldChange{undefined} ** 1024,

    pub fn addChange(self: *State, change: WorldChange) void {
        self.changes[self.change_count] = change;
        self.change_count += 1;
    }

    fn tickConways(self: *State, cell: WorldCell, coords: WorldCoordinates) void {
        switch(cell.cell_type) {
            .Conways => {
                const aliveNeighbors = self.world.countNeighbors(coords, .Conways);
                if (aliveNeighbors < 2) {
                    self.addChange(.{ .coords = coords, .new_cell_type = .Empty });
                } else if (aliveNeighbors > 3) {
                    self.addChange(.{ .coords = coords, .new_cell_type = .Empty });
                }
            },
            .Empty => {
                const aliveNeighbors = self.world.countNeighbors(coords, .Conways);
                if (aliveNeighbors == 3) {
                    self.addChange(.{ .coords = coords, .new_cell_type = .Conways });
                }
            },
        }
    }
};

const WorldChange = struct {
    coords: WorldCoordinates,
    new_cell_type: WorldCell.WorldCellType,
};

export fn init() *anyopaque {
    var allocator = std.heap.c_allocator;
    var state: *State = allocator.create(State) catch @panic("Out of memory");

    state.world.init();
    state.allocator = allocator;

    return state;
}

export fn reload(state_ptr: *anyopaque) void {
    _ = state_ptr;
}

export fn tick(state_ptr: *anyopaque) void {
    var state: *State = @ptrCast(@alignCast(state_ptr));

    if (state.time_state != .Stopped) {
        state.change_count = 0;

        var i: u32 = 0;
        while (i < World.WORLD_LENGTH) : (i += 1) {
            state.tickConways(state.world.cells[i], WorldCoordinates.fromCellIndex(i));
        }

        var c: u32 = 0;
        while (c < state.change_count) : (c += 1) {
            const change = state.changes[c];
            state.world.setTypeAt(change.coords, change.new_cell_type);
        }

        if (state.time_state == .Step) {
            state.time_state = .Stopped;
        }
    }
}

export fn draw(state_ptr: *anyopaque) void {
    var state: *State = @ptrCast(@alignCast(state_ptr));

    var i: u32 = 0;
    while (i < World.WORLD_LENGTH) : (i += 1) {
        const coords = WorldCoordinates.fromCellIndex(i);
        if (state.world.getTypeAt(coords) != .Empty) {
            r.DrawPixel(@intCast(coords.x), @intCast(coords.y), r.WHITE);
        }
    }
}

export fn drawUI(state_ptr: *anyopaque, width: f32) void {
    const state: *State = @ptrCast(@alignCast(state_ptr));
    UI.draw(state, width);
}
