const r = @import("dependencies/raylib.zig");
const State = @import("root.zig").State;

pub fn draw(state: *State, width: f32) void {
    const padding: f32 = 10;
    const button_height: f32 = 30;
    var button_rect: r.Rectangle = .{ .x = padding, .y = padding, .width = width - padding * 2, .height = button_height };

    if (r.GuiButton(button_rect, if (state.time_state == .Stopped) "Start" else "Stop") != 0) {
        state.time_state = if (state.time_state == .Stopped) .Running else .Stopped;
    }
    button_rect.y += button_height + padding;
    if (r.GuiButton(button_rect, "Step") != 0) {
        state.time_state = .Step;
    }
}
