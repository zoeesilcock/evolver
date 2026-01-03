const std = @import("std");
const playground = @import("playground");
const sdl_utils = playground.sdl;
const sdl = playground.sdl.c;
const aseprite = playground.aseprite;

const World = @import("World.zig");
const WorldCell = @import("WorldCell.zig");
const WorldCoordinates = @import("WorldCoordinates.zig");

pub const Vector2 = @Vector(2, f32);
pub const Color = @Vector(4, u8);

pub const X = 0;
pub const Y = 1;
pub const Z = 2;
pub const W = 3;

pub const R = 0;
pub const G = 1;
pub const B = 2;
pub const A = 3;

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

pub const Assets = struct {
    start_button: ?aseprite.AsepriteAsset = null,
    stop_button: ?aseprite.AsepriteAsset = null,
    step_button: ?aseprite.AsepriteAsset = null,
    exit_button: ?aseprite.AsepriteAsset = null,

    fn load(state: *State) void {
        state.assets.start_button = .load("assets/start_button.aseprite", state.renderer, state.allocator);
        state.assets.stop_button = .load("assets/stop_button.aseprite", state.renderer, state.allocator);
        state.assets.step_button = .load("assets/step_button.aseprite", state.renderer, state.allocator);
        state.assets.exit_button = .load("assets/exit_button.aseprite", state.renderer, state.allocator);
    }

    fn unload(state: *State) void {
        state.assets.start_button.?.deinit(state.allocator);
        state.assets.stop_button.?.deinit(state.allocator);
        state.assets.step_button.?.deinit(state.allocator);
        state.assets.exit_button.?.deinit(state.allocator);
    }
};

pub const State = struct {
    allocator: std.mem.Allocator,
    time_state: TimeProgressState,
    world: World,
    change_count: u32,
    changes: [MAX_WORLD_CHANGE_COUNT]WorldChange,

    assets: Assets,
    input: Input,

    window: *sdl.SDL_Window,
    window_width: u32,
    window_height: u32,
    renderer: *sdl.SDL_Renderer,
    render_texture: *sdl.SDL_Texture = undefined,
    dest_rect: sdl.SDL_FRect = undefined,
    world_scale: f32,
    continue_running: bool,

    pub fn exit(state: *State) void {
        state.continue_running = false;
    }

    pub fn startStopMode(state: *State) void {
        state.time_state = if (state.time_state == .Running) .Stopped else .Running;
    }

    pub fn stepMode(state: *State) void {
        state.time_state = .Step;
    }

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

const Input = struct {
    left_mouse_down: bool = false,
    left_mouse_pressed: bool = false,
    left_mouse_last_time: u64 = 0,

    mouse_position: Vector2 = @splat(0),

    pub fn reset(self: *Input) void {
        self.left_mouse_pressed = false;
    }
};

export fn init(window_width: u32, window_height: u32, window: *sdl.SDL_Window) *anyopaque {
    sdl_utils.logError(sdl.SDL_SetWindowTitle(window, "Evolver"), "Failed to set window title");

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

        .assets = .{},
        .input = .{},

        .window = window,
        .window_width = window_width,
        .window_height = window_height,
        .renderer = sdl_utils.panicIfNull(sdl.SDL_CreateRenderer(window, null), "Failed to create renderer.").?,
        .dest_rect = undefined,
        .world_scale = 1,
        .continue_running = true,
    };

    state.world.init();
    state.setupRenderTexture();

    Assets.load(state);

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
    const state: *State = @ptrCast(@alignCast(state_ptr));
    Assets.unload(state);
    Assets.load(state);
}

export fn processInput(state_ptr: *anyopaque) bool {
    const state: *State = @ptrCast(@alignCast(state_ptr));
    var input = &state.input;

    input.reset();

    var event: sdl.SDL_Event = undefined;
    while (sdl.SDL_PollEvent(&event)) {
        if (event.type == sdl.SDL_EVENT_QUIT or
            (event.type == sdl.SDL_EVENT_KEY_DOWN and event.key.key == sdl.SDLK_ESCAPE))
        {
            state.exit();
            break;
        }

        if (event.type == sdl.SDL_EVENT_KEY_DOWN or event.type == sdl.SDL_EVENT_KEY_UP) {
            const is_down = event.type == sdl.SDL_EVENT_KEY_DOWN;
            if (is_down) {
                switch (event.key.key) {
                    sdl.SDLK_RIGHT => state.stepMode(),
                    sdl.SDLK_SPACE => state.startStopMode(),
                    else => {},
                }
            }
        }

        if (event.type == sdl.SDL_EVENT_WINDOW_RESIZED) {
            state.setupRenderTexture();
        }

        if (event.type == sdl.SDL_EVENT_MOUSE_MOTION) {
            input.mouse_position = Vector2{ event.motion.x, event.motion.y };
        } else if (event.type == sdl.SDL_EVENT_MOUSE_BUTTON_DOWN or event.type == sdl.SDL_EVENT_MOUSE_BUTTON_UP) {
            const is_down = event.type == sdl.SDL_EVENT_MOUSE_BUTTON_DOWN;

            switch (event.button.button) {
                1 => {
                    input.left_mouse_pressed = (input.left_mouse_down and !is_down);
                    input.left_mouse_down = is_down;
                },
                else => {},
            }
        }
    }
    return state.continue_running;
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
    }

    _ = sdl.SDL_SetRenderTarget(state.renderer, null);
    {
        _ = sdl.SDL_SetRenderDrawColor(state.renderer, 80, 80, 80, 255);
        _ = sdl.SDL_RenderClear(state.renderer);
        _ = sdl.SDL_RenderTexture(state.renderer, state.render_texture, null, &state.dest_rect);
        drawGameUI(state);
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
    const start_stop_button: ?aseprite.AsepriteAsset =
        if (state.time_state == .Running) state.assets.stop_button else state.assets.start_button;

    const vertical_spacing = 30;

    var position = Vector2{ 10, vertical_spacing };
    if (start_stop_button) |button| {
        const size: Vector2 = .{
            @floatFromInt(button.document.header.width),
            @floatFromInt(button.document.header.height),
        };
        if (state.input.left_mouse_pressed and pointWithinArea(state.input.mouse_position, position, size)) {
            state.startStopMode();
        }
        drawTextureAt(state, button.frames[0], position, @splat(1), @splat(255));

        position[Y] += @floatFromInt(button.document.header.height);
        position[Y] += vertical_spacing;
    }

    if (state.assets.step_button) |button| {
        const size: Vector2 = .{
            @floatFromInt(button.document.header.width),
            @floatFromInt(button.document.header.height),
        };
        if (state.input.left_mouse_pressed and pointWithinArea(state.input.mouse_position, position, size)) {
            state.stepMode();
        }
        drawTextureAt(state, button.frames[0], position, @splat(1), @splat(255));

        position[Y] += @floatFromInt(button.document.header.height);
        position[Y] += vertical_spacing;
    }

    if (state.assets.exit_button) |button| {
        position[Y] += vertical_spacing;

        const size: Vector2 = .{
            @floatFromInt(button.document.header.width),
            @floatFromInt(button.document.header.height),
        };
        if (state.input.left_mouse_pressed and pointWithinArea(state.input.mouse_position, position, size)) {
            state.exit();
        }
        drawTextureAt(state, button.frames[0], position, @splat(1), @splat(255));

        position[Y] += @floatFromInt(button.document.header.height);
        position[Y] += vertical_spacing;
    }
}

fn drawTextureAt(state: *State, texture: *sdl.SDL_Texture, position: Vector2, scale: Vector2, tint: Color) void {
    const texture_rect = sdl.SDL_FRect{
        .x = @round(position[X]),
        .y = @round(position[Y]),
        .w = @as(f32, @floatFromInt(texture.w)) * scale[X],
        .h = @as(f32, @floatFromInt(texture.h)) * scale[Y],
    };

    sdl_utils.panic(sdl.SDL_SetTextureColorMod(texture, tint[R], tint[G], tint[B]), "Failed to set texture color mod.");
    sdl_utils.panic(sdl.SDL_SetTextureAlphaMod(texture, tint[A]), "Failed to set texture alpha mod.");

    _ = sdl.SDL_RenderTexture(state.renderer, texture, null, &texture_rect);
}

fn pointWithinArea(point: Vector2, area_origin: Vector2, area_size: Vector2) bool {
    const relative_point = point - area_origin;
    return relative_point[X] > 0 and
        relative_point[Y] > 0 and
        relative_point[X] <= area_size[X] and
        relative_point[Y] <= area_size[Y];
}
