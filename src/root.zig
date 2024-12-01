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

const MAX_WORLD_CHANGE_COUNT = 1024;

const WorldChange = struct {
    coords: WorldCoordinates,
    new_cell_type: WorldCell.WorldCellType,
};

pub const State = struct {
    allocator: std.mem.Allocator,
    time_state: TimeProgressState,
    world: World,
    change_count: u32,
    changes: [MAX_WORLD_CHANGE_COUNT]WorldChange,

    window_width: u32,
    window_height: u32,
    render_texture: ?r.RenderTexture2D,
    source_rect: ?r.Rectangle,
    dest_rect: ?r.Rectangle,
    world_draw_scale: f32,

    pub fn addChange(self: *State, change: WorldChange) void {
        self.changes[self.change_count] = change;
        self.change_count += 1;
    }

    pub fn tickConways(self: *State, cell: WorldCell, coords: WorldCoordinates) void {
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

    pub fn initializeRenderTexture(self: *State) void {
        self.render_texture = r.LoadRenderTexture(World.WIDTH, World.HEIGHT);

        self.world_draw_scale =
            @as(f32, @floatFromInt(self.window_height)) /
            @as(f32, @floatFromInt(World.WIDTH));
        self.source_rect = r.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(self.render_texture.?.texture.width),
            .height = @floatFromInt(self.render_texture.?.texture.height),
        };
        self.dest_rect = r.Rectangle{ 
            .x = @as(f32, @floatFromInt(self.window_width)) - self.source_rect.?.width * self.world_draw_scale,
            .y = 0,
            .width = self.source_rect.?.width * self.world_draw_scale,
            .height = self.source_rect.?.height * self.world_draw_scale,
        };
    }
};

export fn init(window_width: u32, window_height: u32) *anyopaque {
    var allocator = std.heap.c_allocator;
    var state: *State = allocator.create(State) catch @panic("Out of memory");

    state.allocator = allocator;

    state.world = World{};
    state.world.init();

    state.time_state = .Stopped;
    state.change_count = 0;
    state.changes = [1]WorldChange{undefined} ** MAX_WORLD_CHANGE_COUNT;

    state.window_width = window_width;
    state.window_height = window_height;
    state.render_texture = null;
    state.source_rect = null;
    state.dest_rect = null;
    state.world_draw_scale = 1;

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

    if (state.render_texture == null) {
        state.initializeRenderTexture();
    }

    if (state.render_texture) |render_texture| {
        r.BeginTextureMode(render_texture);
        {
            r.ClearBackground(r.BLACK);

            var i: u32 = 0;
            while (i < World.WORLD_LENGTH) : (i += 1) {
                const coords = WorldCoordinates.fromCellIndex(i);
                if (state.world.getTypeAt(coords) != .Empty) {
                    r.DrawCube(r.Vector3{ .x = @floatFromInt(coords.x), .y = @floatFromInt(coords.y), .z = 0 }, 1, 1, 1, r.WHITE);
                }
            }
        }
        r.EndTextureMode();

        {
            r.ClearBackground(r.DARKGRAY);
            r.DrawTexturePro(render_texture.texture, state.source_rect.?, state.dest_rect.?, r.Vector2{}, 0, r.WHITE);

            UI.draw(state, @as(f32, @floatFromInt(state.window_width)) - state.source_rect.?.width * state.world_draw_scale);
        }
    }
}

