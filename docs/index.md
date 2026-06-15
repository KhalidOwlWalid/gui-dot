# Guidot

**Real-time time-series graph widget for Godot 4.**

Guidot lets you drop a single node into any Godot scene and get a fully interactive, live-updating plot — no boilerplate required.

---

## Quick look

```
YourScene
├── Guidot_Time_Series_Graph   ← add this node
├── Guidot_Data_Server         ← one per scene
└── YourNode
    └── Guidot_Data_Source     ← push data here
```

A `Guidot_Data_Source` collects data channels and forwards them to the `Guidot_Data_Server`. The graph subscribes to whichever channels you select via the in-game wizard.

---

## Version

| Field | Value |
|-------|-------|
| Plugin version | `0.1.0` |
| Godot version | `4.x` |
| License | MIT |
