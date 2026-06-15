# Axis Controls

All axis interactions work at runtime without pausing the game.

## Mouse controls

| Input | Where | Effect |
|-------|-------|--------|
| Scroll up | Over any axis | Zoom in (narrow range) |
| Scroll down | Over any axis | Zoom out (widen range) |
| `Ctrl` + left-drag | Over any axis | Pan the axis |
| Double-click | Over any axis | Open the **Limit Settings** popup |
| Single-click on min/max tick | Y or T axis edge labels | Open **inline editor** for that limit |
| Right-click | Over any axis | Open the axis context menu |

## T-axis modes

The time axis has two operating modes toggled from the wizard or via code.

### Sliding Window (realtime)

The axis automatically advances to follow the newest data point. The visible window width is configurable.

```gdscript
# Set a 30-second rolling window
_t_axis_node.set_window_size_s(30.0)
_t_axis_node.change_graph_mode(Guidot_T_Axis_Canvas.TAxisMode.SLIDING_WINDOW)
```

### Fixed

The axis stays locked to the range you set. Any user interaction (inline edit, limit dialog, zoom, pan) automatically switches to Fixed mode.

```gdscript
_t_axis_node.change_graph_mode(Guidot_T_Axis_Canvas.TAxisMode.FIXED)
```

!!! info
    Opening the **Axis Limit Settings** from the right-click menu while in Sliding Window mode automatically switches to Fixed. Use the **Sliding Window Settings** menu item to go back.

## Limit Settings popup

Double-click any axis to open a small popup where you can type exact min/max values.

- **Min = Max** is rejected (zero-span axis causes division by zero in tick spacing).
- **Min > Max** is allowed — this flips the axis, rendering the plot upside-down.
- Press **Apply** or hit `Enter` to confirm.

## Inline editor

Single-click the leftmost (min) or rightmost (max) tick label on any axis to edit that limit directly on the axis without opening a popup. Press `Enter` to apply, `Escape` to cancel.
