# Example: Basic Sine Wave

The simplest possible Guidot setup — one channel, one data source, live sine wave.

## Scene tree

```
SineWaveDemo (Node)
├── Guidot_Data_Server
├── Guidot_Time_Series_Graph
└── SineProducer (Node)
    ├── Guidot_Data_Source
    └── sine_producer.gd   ← attach this script
```

## Script

```gdscript title="sine_producer.gd"
extends Node

@onready var _client: Guidot_Data_Source = $Guidot_Data_Source

var _sine_channel: Guidot_Data = Guidot_Data.new()
var _t: float = 0.0

func _ready() -> void:
    _sine_channel.set_name("sine")
    _client.register_data_channel(_sine_channel)
    _client.update_server()

func _process(delta: float) -> void:
    _t += delta
    var value: float = sin(_t * 2.0 * PI)   # 1 Hz sine, amplitude ±1
    _client.add_data_point(_sine_channel, value)
```

## Running it

1. Run the scene.
2. Click the gear icon on the graph.
3. In the **Data** tab, tick **sine**.
4. The graph starts plotting a live sine wave.

!!! tip
    To see more of the wave, open the wizard → **T-Axis Setup** → set the sliding window to `5` seconds.
