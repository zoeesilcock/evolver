const r = @import("dependencies/raylib.zig");

const TimeState = enum(u32) {
    Stopped,
    ProcessOneTick,
    Running,
};

time_state: TimeState = .Stopped,

const UI = @This();

pub fn draw(self: *UI, width: f32) void {
    const padding: f32 = 10;
    const button_height: f32 = 30;
    const button_rect: r.Rectangle = .{ .x = padding, .y = padding, .width = width - padding * 2, .height = button_height };

    if (r.GuiButton(button_rect, if (self.time_state == .Stopped) "Start" else "Stop") != 0) {
        self.time_state = if (self.time_state == .Stopped) .Running else .Stopped;
    }
}
