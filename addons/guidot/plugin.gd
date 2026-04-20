@tool
extends EditorPlugin

const _CLOCK_AUTOLOAD_NAME := "GuidotClock"
const _CLOCK_SCRIPT_PATH   := "res://addons/guidot/components/data/guidot_clock.gd"
const _GRAPH_SCRIPT_PATH   := "res://addons/guidot/t_graph_with_panel.gd"

func _enter_tree() -> void:
	# Ensure the clock singleton is always in the scene tree so that any
	# Guidot_Graph node can find it via get_nodes_in_group("Guidot_Clock").
	if not ProjectSettings.has_setting("autoload/%s" % _CLOCK_AUTOLOAD_NAME):
		add_autoload_singleton(_CLOCK_AUTOLOAD_NAME, _CLOCK_SCRIPT_PATH)

	# Register Guidot_Graph as a custom node type so it appears in the
	# "Add Node" dialog under its own name.
	add_custom_type(
		"Guidot_Graph",
		"PanelContainer",
		load(_GRAPH_SCRIPT_PATH),
		null
	)

func _exit_tree() -> void:
	remove_autoload_singleton(_CLOCK_AUTOLOAD_NAME)
	remove_custom_type("Guidot_Graph")
