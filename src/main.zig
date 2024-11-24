const std = @import("std");
const r = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
    @cInclude("rlgl.h");
});

const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 600;
const TARGET_FPS = 60;

pub fn main() !void {
    r.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Evolver");
    r.SetTargetFPS(TARGET_FPS);

    while (!r.WindowShouldClose()) {
        r.BeginDrawing();

        r.ClearBackground(r.BLACK);

        defer r.EndDrawing();
    }

    r.CloseWindow();
}
