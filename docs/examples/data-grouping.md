# Example: Data Grouping

When you have many channels, `Guidot_Data_Group` keeps the wizard's subscriber list readable by collecting related channels under a collapsible header.

## Scene tree

```
GroupingDemo (Node)
├── Guidot_Data_Server
├── Guidot_Time_Series_Graph
└── VehicleNode (Node)
    ├── Guidot_Data_Source
    └── vehicle_telemetry.gd
```

## Script

```gdscript title="vehicle_telemetry.gd"
extends Node

@onready var _client: Guidot_Data_Source = $Guidot_Data_Source

# Motion channels
var _vel_x: Guidot_Data = Guidot_Data.new()
var _vel_y: Guidot_Data = Guidot_Data.new()
var _accel: Guidot_Data = Guidot_Data.new()

# Engine channels
var _rpm:   Guidot_Data = Guidot_Data.new()
var _temp:  Guidot_Data = Guidot_Data.new()

var _t: float = 0.0

func _ready() -> void:
    # Name every channel
    _vel_x.set_name("velocity_x")
    _vel_y.set_name("velocity_y")
    _accel.set_name("acceleration")
    _rpm.set_name("rpm")
    _temp.set_name("temperature")

    # Group: Motion
    var motion_group: Guidot_Data_Group = Guidot_Data_Group.new()
    motion_group.set_name("Motion")
    motion_group.add_channel(_vel_x)
    motion_group.add_channel(_vel_y)
    motion_group.add_channel(_accel)

    # Group: Engine
    var engine_group: Guidot_Data_Group = Guidot_Data_Group.new()
    engine_group.set_name("Engine")
    engine_group.add_channel(_rpm)
    engine_group.add_channel(_temp)

    _client.register_data_group(motion_group)
    _client.register_data_group(engine_group)
    _client.update_server()

func _process(delta: float) -> void:
    _t += delta

    _client.add_data_point(_vel_x, sin(_t))
    _client.add_data_point(_vel_y, cos(_t))
    _client.add_data_point(_accel, sin(_t * 2.0) * 9.8)
    _client.add_data_point(_rpm,   3000.0 + sin(_t * 0.5) * 1000.0)
    _client.add_data_point(_temp,  90.0   + sin(_t * 0.1) * 10.0)
```

## Result in the wizard

The **Data** tab will show two collapsible sections:

```
▼ Motion
    ☑ velocity_x
    ☑ velocity_y
    ☑ acceleration
▼ Engine
    ☑ rpm
    ☑ temperature
```

Tick individual channels or collapse groups you are not interested in to reduce visual noise.

!!! tip
    Channels that are not registered inside any group still appear in the wizard — they show up in an **Ungrouped** section at the bottom.
