# Overview

Setting up Guidot takes three steps:

1. **Declare your data channels** — create `Guidot_Data` objects that name each stream.
2. **Push data** — call `add_data_point()` on your `Guidot_Data_Source` each frame (or on demand).
3. **Subscribe** — open the in-game wizard and tick the channels you want to see.

## Minimal GDScript setup

```gdscript
extends Node

# 1. References to the Guidot nodes (add them in the scene tree)
@onready var _client: Guidot_Data_Source = $Guidot_Data_Source

# 2. Declare a channel
var _speed_channel: Guidot_Data = Guidot_Data.new()

func _ready() -> void:
    _speed_channel.set_name("speed")
    _client.register_data_channel(_speed_channel)
    _client.update_server()   # tell the server about the new channel

func _process(delta: float) -> void:
    var speed: float = calculate_speed()          # your value
    var t: float     = Time.get_ticks_msec() / 1000.0
    _client.add_data_point(_speed_channel, speed)
```

!!! note
    `add_data_point` uses the server's internal clock for the timestamp. You do not need to pass `t` manually unless you want custom timestamps.

## In-game workflow

| Action | How |
|--------|-----|
| Open wizard | Press the gear icon on the graph, or right-click → **Settings** |
| Subscribe to a channel | Tick the checkbox next to its name in the **Data** tab |
| Change Y-axis count | Wizard → **Y-Axis Setup** |
| Switch T-axis mode | Wizard → **T-Axis Setup** → choose Realtime or Fixed |
| Adjust opacity | Wizard → **Graph** → Opacity slider |
| Zoom | Scroll wheel over an axis |
| Pan | `Ctrl` + left-drag over an axis |
| Set exact limits | Double-click an axis to open the limit dialog |
| Edit inline | Single-click a min/max tick label |
| Move graph | Press `E` to enter Edit mode, then drag |
| Resize graph | Press `E`, then drag a corner handle |
