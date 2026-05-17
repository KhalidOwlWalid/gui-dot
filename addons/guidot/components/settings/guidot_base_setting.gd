# Class that handles basic guidot settings configuration through JSON to ensure uniformity throughout
# the guidot nodes
class_name Guidot_Base_Setting
extends Resource

signal configured

static var gd_node_ref: String = "guidot_node_ref"
static var gd_node_id_key: String = "guidot_node_id"
static var gd_type_key: String = "guidot_type"
static var global_key: String = "global"
static var preferences_key: String = "preferences"
static var local_key: String = "local"
static var y_axis_key: String = "y_axis"
static var x_axis_key: String = "x_axis"
static var axis_range: String = "axis_range"
static var axis_count_key: String = "axis_count"
static var left_axis_count_key: String = "left_axis"
static var right_axis_count_key: String = "right_axis"
static var disable_hotkey_key: String = "disable_hotkey"
static var opacity_key: String = "opacity"
static var graph_mode_key: String = "graph_mode"
static var sync_with_global_key: String = "sync_with_global"

static var selection_type_key: String = "ui_type"
static var value_key: String = "value"
static var default_value_key: String = "default_value"
static var tooltip_key: String = "tooltip"
static var dropdown_selection_key: String = "dropdown_selection"
static var enum_selection_key: String = "enum_selection"

static var common_keys: Array = [Guidot_Base_Setting.selection_type_key, Guidot_Base_Setting.value_key]

enum SelectionType {
	DROPDOWN,
	LINE_EDIT_FLOAT,
	CHECKBOX,
}

var _settings: Dictionary = {
	"graph_node_ref": "<gd_node_ref>",
	"graph_node_id": "<Node_ID>",
	"graph_type": "Guidot_Time_Series_Graph",
	"global": {
		"preferences": {
			"disable_hotkeys": Guidot_Base_Setting.create_selection_type(SelectionType.CHECKBOX, false),
			"opacity": ["line_edit", 100],
			"graph_mode": ["dropdown", 0]
		},
	},

	"local": {
		"preferences": {
			"disable_hotkeys": ["checkbox", false],
			"opacity": 100,
			"graph_mode": 0,
			"sync_with_global": false,
		},
	},

	"y_axis": {
		"axis_count": {
			"n_left_axis": 1,
			"n_right_axis": 1,
		},
		"axis_range": {
			Guidot_Y_Axis_Canvas.AxisPosition.PRIMARY_LEFT: Vector2(0, 100),
		}
	},

	"x_axis": {
		"axis_range": Vector2(0, 20)
	}
}

func setup_base_settings(node_ref: String, node_id: String) -> void:
	self._settings[gd_node_ref] = node_ref
	self._settings[gd_node_id_key] = node_id

static func create_selection_type(ui_type: SelectionType, val: Variant, dropdown_selection: Array = [], enum_ref: Variant = null)-> Dictionary:
	var config_dict: Dictionary
	config_dict[Guidot_Base_Setting.selection_type_key] = ui_type
	config_dict[Guidot_Base_Setting.value_key] = val
	config_dict[Guidot_Base_Setting.tooltip_key] = ""
	config_dict[Guidot_Base_Setting.dropdown_selection_key] = dropdown_selection
	config_dict[Guidot_Base_Setting.enum_selection_key] = enum_ref
	return config_dict
