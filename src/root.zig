const std = @import("std");
const sdl_utils = @import("sdl");
const sdl = @import("sdl").c;

const World = @import("World.zig");
const WorldCell = @import("WorldCell.zig");
const WorldCoordinates = @import("WorldCoordinates.zig");

const DebugAllocator = std.heap.DebugAllocator(.{
    .enable_memory_limit = true,
    .retain_metadata = true,
    .never_unmap = true,
});

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

    window: *sdl.SDL_Window,
    window_width: u32,
    window_height: u32,
    renderer: *sdl.SDL_Renderer,
    render_texture: *sdl.SDL_Texture = undefined,
    dest_rect: sdl.SDL_FRect = undefined,
    world_scale: f32,

    pub fn addChange(self: *State, change: WorldChange) void {
        self.changes[self.change_count] = change;
        self.change_count += 1;
    }

    pub fn tickConways(self: *State, cell: WorldCell, coords: WorldCoordinates) void {
        switch (cell.cell_type) {
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

    pub fn setupRenderTexture(self: *State) void {
        _ = sdl.SDL_GetWindowSize(self.window, @ptrCast(&self.window_width), @ptrCast(&self.window_height));
        self.world_scale = @as(f32, @floatFromInt(self.window_height)) / @as(f32, @floatFromInt(World.WIDTH));

        const horizontal_offset: f32 = @as(f32, @floatFromInt(self.window_width)) -
            (@as(f32, @floatFromInt(World.WIDTH)) * self.world_scale);
        self.dest_rect = sdl.SDL_FRect{
            .x = horizontal_offset,
            .y = 0,
            .w = @as(f32, @floatFromInt(World.WIDTH)) * self.world_scale,
            .h = @as(f32, @floatFromInt(World.HEIGHT)) * self.world_scale,
        };

        self.render_texture = sdl_utils.panicIfNull(sdl.SDL_CreateTexture(
            self.renderer,
            sdl.SDL_PIXELFORMAT_RGBA32,
            sdl.SDL_TEXTUREACCESS_TARGET,
            @intCast(World.WIDTH),
            @intCast(World.HEIGHT),
        ), "Failed to initialize main render texture.");

        sdl_utils.panic(
            sdl.SDL_SetTextureScaleMode(self.render_texture, sdl.SDL_SCALEMODE_NEAREST),
            "Failed to set scale mode for the main render texture.",
        );
    }
};

export fn init(window_width: u32, window_height: u32, window: *sdl.SDL_Window) *anyopaque {
    var backing_allocator = std.heap.c_allocator;

    var game_allocator = (backing_allocator.create(DebugAllocator) catch @panic("Failed to initialize game allocator."));
    game_allocator.* = .init;

    var allocator = game_allocator.allocator();

    var state: *State = allocator.create(State) catch @panic("Out of memory");
    state.* = .{
        .allocator = allocator,

        .world = .{},

        .time_state = .Stopped,
        .change_count = 0,
        .changes = [1]WorldChange{undefined} ** MAX_WORLD_CHANGE_COUNT,

        .window = window,
        .window_width = window_width,
        .window_height = window_height,
        .renderer = sdl_utils.panicIfNull(sdl.SDL_CreateRenderer(window, null), "Failed to create renderer.").?,
        .dest_rect = undefined,
        .world_scale = 1,
    };

    state.world.init();
    state.setupRenderTexture();

    return state;
}

export fn deinit(state_ptr: *anyopaque) void {
    const state: *State = @ptrCast(@alignCast(state_ptr));
    sdl.SDL_DestroyRenderer(state.renderer);
}

export fn willReload(state_ptr: *anyopaque) void {
    _ = state_ptr;
}

export fn reloaded(state_ptr: *anyopaque) void {
    _ = state_ptr;
}

export fn processInput(state_ptr: *anyopaque) bool {
    const state: *State = @ptrCast(@alignCast(state_ptr));

    var continue_running: bool = true;
    var event: sdl.SDL_Event = undefined;
    while (sdl.SDL_PollEvent(&event)) {
        if (event.type == sdl.SDL_EVENT_QUIT or
            (event.type == sdl.SDL_EVENT_KEY_DOWN and event.key.key == sdl.SDLK_ESCAPE))
        {
            continue_running = false;
            break;
        }

        if (event.type == sdl.SDL_EVENT_KEY_DOWN or event.type == sdl.SDL_EVENT_KEY_UP) {
            const is_down = event.type == sdl.SDL_EVENT_KEY_DOWN;
            if (is_down) {
                switch (event.key.key) {
                    sdl.SDLK_RIGHT => state.time_state = .Step,
                    sdl.SDLK_SPACE => state.time_state = if (state.time_state == .Running) .Stopped else .Running,
                    else => {},
                }
            }
        }

        if (event.type == sdl.SDL_EVENT_WINDOW_RESIZED) {
            state.setupRenderTexture();
        }
    }
    return continue_running;
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

    sdl_utils.panic(sdl.SDL_SetRenderTarget(state.renderer, state.render_texture), "Failed to set render target.");
    {
        _ = sdl.SDL_SetRenderDrawColor(state.renderer, 0, 0, 0, 255);
        _ = sdl.SDL_RenderClear(state.renderer);
        drawWorld(state);
        drawGameUI(state);
    }

    _ = sdl.SDL_SetRenderTarget(state.renderer, null);
    {
        _ = sdl.SDL_SetRenderDrawColor(state.renderer, 80, 80, 80, 255);
        _ = sdl.SDL_RenderClear(state.renderer);
        _ = sdl.SDL_RenderTexture(state.renderer, state.render_texture, null, &state.dest_rect);
    }
    _ = sdl.SDL_RenderPresent(state.renderer);
}

fn drawWorld(state: *State) void {
    var i: u32 = 0;
    while (i < World.WORLD_LENGTH) : (i += 1) {
        const coords = WorldCoordinates.fromCellIndex(i);
        if (state.world.getTypeAt(coords) != .Empty) {
            const dest_rect = sdl.SDL_FRect{
                .x = @floatFromInt(coords.x),
                .y = @floatFromInt(coords.y),
                .w = 1,
                .h = 1,
            };
            _ = sdl.SDL_SetRenderDrawColor(state.renderer, 255, 255, 255, 255);
            _ = sdl.SDL_RenderFillRect(state.renderer, &dest_rect);
        }
    }
}

fn drawGameUI(state: *State) void {
    _ = state;
}
