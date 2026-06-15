# Configuration

## In-game wizard

The wizard is the primary configuration UI. Open it at runtime by clicking the gear icon on the graph.

### Graph tab

| Setting | Description |
|---------|-------------|
| Opacity | Transparency of the whole graph (0 = invisible, 1 = opaque) |
| Graph Mode | `FIXED` — data is buffered to a fixed size. `REALTIME` — sliding window follows live data. |

### Y-Axis Setup tab

| Setting | Description |
|---------|-------------|
| Left axis count | Number of Y-axes on the left side (1–6) |
| Right axis count | Number of Y-axes on the right side (0–6) |

Adding or removing axes takes effect immediately. Each channel must be (re-)assigned to an axis after changing the count.

### T-Axis Setup tab

| Setting | Description |
|---------|-------------|
| Sliding window size (s) | Width of the rolling window in seconds when in Realtime mode |
| Fixed min / max | Exact time range when in Fixed mode |

### Data tab

Lists all registered channels grouped by their `Guidot_Data_Group`. Tick a channel to subscribe the graph to it. The channel immediately appears (or disappears) on the plot.

## Programmatic configuration

All wizard settings are also accessible via GDScript on the `Guidot_Time_Series_Canvas` reference inside the graph node.

```gdscript
@onready var _canvas = $Guidot_Time_Series_Graph._guidot_ts_canvas

# Switch T-axis to realtime with a 15-second window
_canvas._t_axis_node.set_window_size_s(15.0)
_canvas._t_axis_node.change_graph_mode(Guidot_T_Axis_Canvas.TAxisMode.SLIDING_WINDOW)

# Set a fixed Y range on the first axis
var handler = _canvas._y_axis_manager.get_available_axis_handler()[0]
handler.get_axis_node().setup_axis_range(-10.0, 10.0)
```
