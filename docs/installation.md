# Installation

## Requirements

- Godot **4.x**
- No external dependencies

## Steps

### 1. Copy the addon

Copy the `addons/guidot/` folder into your project's `addons/` directory:

```
your_project/
└── addons/
    └── guidot/          ← copy this folder
        ├── plugin.cfg
        ├── plugin.gd
        ├── guidot_time_series_canvas.gd
        ├── guidot_time_series_graph.gd
        └── ...
```

### 2. Enable the plugin

In the Godot editor:

1. Open **Project → Project Settings**
2. Go to the **Plugins** tab
3. Find **Guidot** in the list and set its status to **Enabled**

### 3. Add required nodes to your scene

The minimum scene tree you need:

```
YourScene (Node or any root)
├── Guidot_Data_Server
├── Guidot_Time_Series_Graph
└── YourDataProducerNode
    └── Guidot_Data_Source
```

!!! tip
    `Guidot_Data_Server` auto-discovers all `Guidot_Data_Source` nodes in the scene tree on `_ready`. You do not need to wire them together manually.

### 4. Verify

Run the scene. The graph should appear with an empty plot and default axes. Right-click the graph to open the configuration wizard and subscribe to data channels.
