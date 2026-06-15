# Introduction

## What is Guidot?

Guidot is a Godot 4 plugin that provides an interactive, real-time time-series graph widget. It is designed for games or tools that need to **visualise live numeric data** — physics values, AI state, network metrics, sensor readings, or any float stream — without leaving the Godot editor or writing custom rendering code.

## Core concepts

### The graph node

`Guidot_Time_Series_Graph` is the top-level node you add to your scene. It owns the canvas, axes, and all UI chrome. You can have multiple independent graphs in the same scene.

### Server / client architecture

Data flows through a lightweight publish-subscribe system:

```
Guidot_Data_Source  ──push──▶  Guidot_Data_Server  ──query──▶  Guidot_Time_Series_Graph
```

| Node | Role |
|------|------|
| `Guidot_Data_Source` | Lives next to (or inside) the node that produces data. You call `add_data_point()` on it each frame or whenever a new value is ready. |
| `Guidot_Data_Server` | Central store. Receives data from all clients in the scene tree. The graph queries it every frame. |
| `Guidot_Data` | A named channel descriptor — one per data stream (e.g. `"velocity_x"`, `"rpm"`). |
| `Guidot_Data_Group` | Optional grouping of related channels shown together in the subscriber UI. |

### Axes

| Axis | Class | Notes |
|------|-------|-------|
| Time (T) | `Guidot_T_Axis_Canvas` | Horizontal axis. Supports **Sliding Window** (auto-follows latest data) and **Fixed** (user-locked range). |
| Value (Y) | `Guidot_Y_Axis_Canvas` | Vertical axis. Up to 6 left + 6 right independently scaled axes. |

## Key features

- **Zero-config startup** — add the nodes, push data, done.
- **In-game wizard** — configure Y-axes, T-axis range, opacity, and buffer mode without pausing the game.
- **Interactive axes** — scroll to zoom, `Ctrl`+drag to pan, double-click to open the limit editor, single-click a tick label to edit inline.
- **Data grouping** — organise related channels so the subscriber UI stays clean.
- **Edit mode** — press `E` to enter edit mode; drag to move the graph, grab corners to resize it.
