# Example: Multiple Channels

Plot several independent signals on the same graph with separate Y-axes.

## Scene tree

```
MultiChannelDemo (Node)
├── Guidot_Data_Server
├── Guidot_Time_Series_Graph
└── SignalProducer (Node)
    ├── Guidot_Data_Source
    └── signal_producer.gd
```

## Script

```gdscript title="signal_producer.gd"
extends Node

@onready var _client: Guidot_Data_Source = $Guidot_Data_Source

var _sine_channel:   Guidot_Data = Guidot_Data.new()
var _cosine_channel: Guidot_Data = Guidot_Data.new()
var _noise_channel:  Guidot_Data = Guidot_Data.new()

var _t: float = 0.0

func _ready() -> void:
    _sine_channel.set_name("sine")
    _cosine_channel.set_name("cosine")
    _noise_channel.set_name("noise")

    _client.register_data_channel(_sine_channel)
    _client.register_data_channel(_cosine_channel)
    _client.register_data_channel(_noise_channel)
    _client.update_server()

func _process(delta: float) -> void:
    _t += delta

    _client.add_data_point(_sine_channel,   sin(_t * TAU))
    _client.add_data_point(_cosine_channel, cos(_t * TAU))
    _client.add_data_point(_noise_channel,  randf_range(-0.5, 0.5))
```

## Assigning channels to axes

By default all subscribed channels share the first Y-axis. To spread them across independent axes:

1. Open the wizard → **Y-Axis Setup** → set Left axis count to `2`.
2. In the **Data** tab, subscribe all three channels.
3. Assign `sine` and `cosine` to **Y-Axis 1**, and `noise` to **Y-Axis 2**.

Each axis can then be zoomed and panned independently.

!!! note
    Channels on different axes are drawn in different colours automatically. The colour is inherited from the axis's display colour.
