class_name Guidot_Time_Series_Canvas
extends Guidot_Common

# Property of the graph
var window_size: Vector2
var window_color: Color

signal ui_action_request
signal parent_focus_requested
signal axis_configured(available_axis: Array)

const _sync_data_global_key: String = "sync_data_global"
const _opacity_key: String = "opacity"
const _graph_buffer_mode_key: String = "graph_mode"

const _y_axis_setup_key: String = "y_axis_setup"
const _left_axis_count_key: String = "left_axis_count"
const _right_axis_count_key: String = "right_axis_count"

const _t_axis_setup_key: String = "t_axis_setup"
const _t_axis_range_key: String = "sliding_window_size"

@onready var _config_tree: Dictionary = {
	"graph_node_ref": str(self),
	"graph_node_id": str(self.get_instance_id()),
	"guidot_type": str(self.name),
	_GBS.global_key: {
		# TODO: Sync all graphs configuration
		self._sync_data_global_key: _GBS.create_selection_type(_GBS.SelectionType.CHECKBOX, self._sync_data_global),
		# self._opacity_key: _GBS.create_float_edit_type(_GBS.SelectionType.SLIDER, self.color.a, 0.0, 1.0, 0.05),
	},
	_GBS.local_key: {
		self._opacity_key: _GBS.create_float_edit_type(_GBS.SelectionType.SLIDER, self.color.a, 0.0, 1.0, 0.05),
		self._graph_buffer_mode_key: _GBS.create_selection_type(_GBS.SelectionType.DROPDOWN, Guidot_Common.Graph_Buffer_Mode.FIXED,
			Guidot_Common.Graph_Buffer_Mode.keys(), Guidot_Common.Graph_Buffer_Mode),
	},
	self._y_axis_setup_key: {
		self._left_axis_count_key: _GBS.create_float_edit_type(_GBS.SelectionType.LINE_EDIT_FLOAT, 1, 1, 6, 1),
		self._right_axis_count_key: _GBS.create_float_edit_type(_GBS.SelectionType.LINE_EDIT_FLOAT, 0, 0, 6, 1),
	},
	self._t_axis_setup_key: {
		"realtime_setup": {
			self._t_axis_range_key: _GBS.create_float_edit_type(_GBS.SelectionType.LINE_EDIT_FLOAT, 10, 0, 10000, 10),
		}
	}
}

# Handles all the user configuration
# Communicates through the use of Guidot Wizard
func _apply_user_config(branch_name: String, new_value: Variant):
	# Only react to relevant config changes. If opacity changed, update modulation;
	# otherwise just queue a redraw.
	if branch_name == null:
		queue_redraw()
		return

	var branch_path: Array = branch_name.rsplit(".")
	var leaf_key: String = branch_path[-1]

	Guidot_Wizard.set_config_tree_value(self._config_tree, branch_path, new_value)

	# If opacity changed, read the value from the config tree and apply it.
	# if key == self._opacity_key:
	match (leaf_key):

		self._opacity_key:

			var alpha: float = new_value
			alpha = clamp(alpha, 0.0, 1.0)
			# Only apply when the value actually changed to avoid unnecessary redraws
			if alpha != self.get_self_modulate().a:
				self._on_graph_opacity_changed(alpha)
		
		self._graph_buffer_mode_key:
			# self.t_axis_node.change_graph_mode(
			var selected_mode: Graph_Buffer_Mode = new_value

			match (selected_mode):
				Graph_Buffer_Mode.FIXED:
					self.t_axis_node.change_graph_mode(Guidot_T_Axis_Canvas.TAxisMode.FIXED)
				Graph_Buffer_Mode.REALTIME:
					self.t_axis_node.change_graph_mode(Guidot_T_Axis_Canvas.TAxisMode.SLIDING_WINDOW)
				_:
					self.t_axis_node.change_graph_mode(Guidot_T_Axis_Canvas.TAxisMode.SLIDING_WINDOW)
			queue_redraw()

		self._left_axis_count_key:
			var left_axis_count: int = new_value
			var right_axis_count: int = self._config_tree[self._y_axis_setup_key][self._right_axis_count_key][_GBS.value_key]
			self._on_y_axis_changes_applied(Vector2(left_axis_count, right_axis_count))
			self._update_axis_selection()

		self._right_axis_count_key:
			var right_axis_count: int = new_value
			var left_axis_count: int = self._config_tree[self._y_axis_setup_key][self._left_axis_count_key][_GBS.value_key]
			self._on_y_axis_changes_applied(Vector2(left_axis_count, right_axis_count))
			self._update_axis_selection()

		self._t_axis_range_key:
			var range_s: float = new_value
			self.t_axis_node.set_window_size_s(range_s)

			queue_redraw()

func _update_axis_selection():
	self.get_tree().call_group(Guidot_Common._wizard_group_name, "update_available_axes", self._y_axis_manager.get_available_axis_pos())

# Note (Khalid): For now, I wish to standardize the font throughout the whole node
# This may bite me in the future, if for some reason, I wish to have different fonts
# for different parts of the graph, but I kinda doubt that would happen
@onready var font_node: SystemFont = SystemFont.new()

# TODO (Khalid): This should only be temporary for prototyping, but the plugin is created
# I need to find a better way to interface this
var _guidot_server: Guidot_Data_Server
var _curr_data_str: String
@onready var _selected_channels_name: Array = []
@onready var _guidot_clock_node: Guidot_Clock = self.get_tree().get_nodes_in_group(Guidot_Common._clock_group_name)[0]

@onready var default_window_size: Vector2 = Vector2(620, 360)
@onready var default_window_color: Color = Guidot_Utils.get_color("gd_black")
@onready var prev_display_color: Color = default_window_color

# Components used for building the graph 
@onready var plot_node: Guidot_Plot_Canvas = Guidot_Plot_Canvas.new()
@onready var t_axis_node: Guidot_T_Axis_Canvas = Guidot_T_Axis_Canvas.new()

@onready var _setting_button: Button = Button.new()
@onready var _setting_icon: Texture2D = load("res://addons/guidot/icons/gear_icon.png")

@onready var _guidot_wizard: Guidot_Wizard
@onready var _graph_selected: bool = false

func _on_setting_pressed(show_settings: bool) -> void:
	var graph_in_focus_name: String = ""

	if (show_settings):
		graph_in_focus_name = self.name
	self.get_tree().call_group(Guidot_Common._graph_group_name, self._graph_in_focus_callback_name, graph_in_focus_name)
	self.log(LOG_DEBUG, ["Current opacity value is: ", self._config_tree[_GBS.local_key][self._opacity_key]["value"]])

@onready var _pause_button: Button = Button.new()
@onready var _pause_icon: Texture2D = load("res://addons/guidot/icons/pause_icon.png")
@onready var _play_icon: Texture2D = load("res://addons/guidot/icons/play_icon.png")

func _on_pause_pressed() -> void:
	self._is_pause = not self._is_pause
	if (self._is_pause):
		self._pause_button.set_button_icon(self._play_icon)
		self.ui_action_request.emit(Guidot_Common.UI_Action.PAUSE_MODE)
	else:
		self._pause_button.set_button_icon(self._pause_icon)
		self.ui_action_request.emit(Guidot_Common.UI_Action.RESUME_MODE)
	self.log(LOG_DEBUG, ["Pause pressed"])

@onready var _edit_button: Button = Button.new()
@onready var _edit_icon: Texture2D = load("res://addons/guidot/icons/edit_icon.png")

func _on_edit_pressed() -> void:
	self.ui_action_request.emit(Guidot_Common.UI_Action.EDIT_MODE)

@onready var _cursor_button: Button = Button.new()
@onready var _cursor_icon: Texture2D = load("res://addons/guidot/icons/cursor_icon.png")

func _on_cursor_pressed() -> void:
	self.ui_action_request.emit(Guidot_Common.UI_Action.CURSOR_MODE)

@onready var _toggle_graph_button: Button = Button.new()
@onready var _toggle_graph_icon: Texture2D = load("res://addons/guidot/icons/toggle_graph_icon.png")

func _on_toggle_graph_pressed() -> void:
	self.ui_action_request.emit(Guidot_Common.UI_Action.TOGGLE_GRAPH_MODE)
	
	if (self.t_axis_node.get_current_t_axis_mode() == Guidot_T_Axis_Canvas.TAxisMode.FIXED):
		self.t_axis_node.change_graph_mode(Guidot_T_Axis_Canvas.TAxisMode.SLIDING_WINDOW)
	else:
		self.t_axis_node.change_graph_mode(Guidot_T_Axis_Canvas.TAxisMode.FIXED)

@onready var _hide_graph_button: Button = Button.new()
@onready var _hide_graph_icon: Texture2D = load("res://addons/guidot/icons/hide_icon.png")

func _on_hide_graph_pressed() -> void:
	self.visible = not self.visible

@onready var hotkey_enable: bool = true
@onready var _toggle_hotkey_button: Button = Button.new()
@onready var _toggle_hotkey_icon: Texture2D = load("res://addons/guidot/icons/toggle_hotkey_icon.png")

@onready var _sync_data_global: bool = false

func _on_toggle_hotkey_pressed() -> void:
	self.hotkey_enable = not self.hotkey_enable
	self.ui_action_request.emit(Guidot_Common.UI_Action.TOGGLE_HOTKEYS)

@onready var _ui_icons: Array = [
	self._setting_icon,
	self._play_icon,
	self._pause_icon,
	self._edit_icon,
	self._cursor_icon,
	self._toggle_graph_icon,
	self._hide_graph_icon,
	self._toggle_hotkey_icon,
]

@onready var _ui_buttons: Array = [
	self._setting_button,
	self._pause_button,
	self._edit_button,
	self._cursor_button,
	self._toggle_graph_button,
	self._hide_graph_button,
	self._toggle_hotkey_button,
]

var _prev_opacity_setting: float

var _initialized: bool = false

class AxisHandler:

	signal id_reassigned

	# Axis position ensures that when we draw the axis, it will handle the offset from the plot frame
	# accordingly, where an axis_pos of -1, will be drawn left to the plot frame, axis_pos of -2 drawn left
	# to the first y-axis etc.
	# axis_pos of 1 will draw to the right of the plot frame etc.
	var _axis_pos: Guidot_Y_Axis_Canvas.AxisPosition

	var _axis_id: int
	var _axis_node: Guidot_Y_Axis_Canvas
	var _in_use: bool
	var _use_count: int = 0
	var _master_graph_node: Guidot_Time_Series_Canvas

	func init_axis(parent: Node, axis_id: Guidot_Y_Axis_Canvas.AxisPosition, axis_range: Vector2, in_use: bool = false):
		self._axis_node = Guidot_Y_Axis_Canvas.new()
		self._axis_node.setup_axis_range(axis_range.x, axis_range.y)
		self._axis_node
		self._axis_pos = axis_id
		self._in_use = in_use
		self._axis_node.axis_limit_changed.connect(self._on_axis_changed)
		self._master_graph_node = parent
		parent.add_child(self._axis_node)

	func use_axis(flag: bool) -> void:
		self._in_use = flag

	func set_axis_id(id: Guidot_Y_Axis_Canvas.AxisPosition) -> void:
		# TODO (Khalid): Check if the y-axis ID is valid or not
		self._axis_pos = id

	func set_axis_range(new_range: Vector2, trigger_redraw: bool = true) -> void:
		self._axis_node.setup_axis_range(new_range.x, new_range.y, trigger_redraw)

	func set_axis_modulation(modulated_color: Color):
		# self._axis_node.set_self_modulate(modulated_color)
		self._axis_node.color = modulated_color

	func get_axis_range() -> Vector2:
		return self._axis_node.get_axis_range()

	func get_axis_diff() -> float:
		return abs(self._axis_node.max_val - self._axis_node.min_val)

	func is_in_use() -> bool:
		return self._in_use

	func get_axis_node() -> Guidot_Y_Axis_Canvas:
		return self._axis_node

	func get_axis_id() -> Guidot_Y_Axis_Canvas.AxisPosition:
		return self._axis_pos

	func get_axis_width() -> int:
		return self._axis_node.get_axis_width()

	func _on_axis_changed() -> void:
		self._master_graph_node.plot_realtime_data()

	func clear_use_count() -> void:
		self._use_count = 0

	func increment_use_count() -> void:
		self._use_count += 1

	func decrement_use_count() -> void:
		self._use_count -= 1

	func get_use_count() -> int:
		return self._use_count

	func reassign_axis_id(new_ax_id: Guidot_Y_Axis_Canvas.AxisPosition) -> void:
		self._ax_id = new_ax_id
		self.id_reassigned.emit(self._axis_pos)

# For handling multiple y-axis
class AxisManager:

	signal updated

	# Format: { (int)<Guidot_Y_Axis_Canvas.AxisPosition>: (Node)<AxisHandler Node> }
	var _axis_manager: Dictionary
	# Format: { (int)<Guidot_Data_RefCounted>: (String)<Guidot_Y_Axis_Canvas.AxisPosition> }
	var _data_to_axis_map: Dictionary
	var _parent_node: Node
	var _tag: String = "Axis_Manager"

	# TODO: This should initialize with a default, mandatory primary y-axis
	# This is to ensure we always have at least a single y-axis to display
	func init_axis_manager(parent_node: Node) -> void:
		self._parent_node = parent_node
		self.add_axis_handler(Guidot_Y_Axis_Canvas.AxisPosition.PRIMARY_LEFT)

	func add_data_to_axis(gd_data_server: Guidot_Data_Server, chan_name: String, axis_id_enum_str: String) -> bool:
		var gd_data_node: Guidot_Data = gd_data_server.get_channel_id(chan_name)
		# TODO (Khalid): Check if the following already exists or not
		# Also, need to check if the user has deselect the channel, it should not be assigned to any id
		self._data_to_axis_map[gd_data_node] = axis_id_enum_str
		return true

	func set_data_to_axis(gd_data_server: Guidot_Data_Server, chan_name: String, axis_id_enum_str: String) -> bool:
		var gd_data_node: Guidot_Data = gd_data_server.get_channel_id(chan_name)
		# If the data node already exists in the map, then simply re-assigned the axis id
		if gd_data_node in self._data_to_axis_map.keys():
			self._data_to_axis_map[gd_data_node] = axis_id_enum_str
		else:
			self.add_data_to_axis(gd_data_server, chan_name, "PRIMARY_LEFT")

		return true

	func set_data_node_to_axis(gd_data_node: Guidot_Data, axis_id_enum_str: String):
		var axis_exist: bool = self.has_axis_handler(Guidot_Y_Axis_Canvas.AxisPosition[axis_id_enum_str])
		var gd_data_exist_in_map: bool = gd_data_node in self._data_to_axis_map.keys()
		if gd_data_exist_in_map and axis_exist:
			self._data_to_axis_map[gd_data_node] = axis_id_enum_str
		elif (not axis_exist):
			self._data_to_axis_map[gd_data_node] = "PRIMARY_LEFT"
		else:
			self._data_to_axis_map[gd_data_node] = "PRIMARY_LEFT"

		return true

	func remove_data_from_axis(new_data_array: Array[Guidot_Data]):
		for gd_node in self._data_to_axis_map.keys():
			if (not gd_node in new_data_array):
				self._data_to_axis_map.erase(gd_node)

	# Returning channel name and color to ease the process of drawing the axis title and labelling the title based on the line color
	func get_chan_name_and_color_on_axis(axis_pos: Guidot_Y_Axis_Canvas.AxisPosition) -> Array[Array]:
		var chan_name_and_color: Array[Array]

		for data_node in self._data_to_axis_map.keys():
			if (self._data_to_axis_map[data_node] == Guidot_Y_Axis_Canvas.get_axis_id_str_from_value(axis_pos)):
				chan_name_and_color.append([data_node.get_name(), data_node.get_line_color()])

		return chan_name_and_color

	func get_data_to_axis_map() -> Dictionary:
		return self._data_to_axis_map

	# TODO: This function should take care of any conflict between the assigned axis
	# Each axis should have its own unique AxisID and should not conflict
	# If conflicts occur, axis manager should handle this smartly
	# Returns 0 if invalid ID has been chosen
	func add_axis_handler(ax_pos: Guidot_Y_Axis_Canvas.AxisPosition, axis_range: Vector2 = Vector2(-1, 1)) -> Guidot_Y_Axis_Canvas.AxisPosition:
		
		if (ax_pos not in Guidot_Y_Axis_Canvas.AxisPosition.values()):
			Guidot_Log.gd_log(Guidot_Log.Log_Level.WARNING, self._tag, ["Invalid Axis ID (", ax_pos, ") has been passed."])
			Guidot_Log.gd_log(Guidot_Log.Log_Level.WARNING, self._tag, ["Please choose from the following options: ", Guidot_Y_Axis_Canvas.AxisPosition.keys()])
			return 0

		var ax1: AxisHandler = AxisHandler.new()
		
		# TODO: Check if an invalid ID has been passed
		if (self.has_axis_handler(ax_pos)):
			Guidot_Log.gd_log(Guidot_Log.Log_Level.WARNING, self._tag, [ax_pos, " is already available. Please select another AxisID."])
			return 0

		if (not self._axis_manager.is_empty()):
			# Isolate left and right axis for ease of comparison later
			var all_left_axis: Array = self._axis_manager.keys().filter(func(n): return n < 0)
			var all_right_axis: Array = self._axis_manager.keys().filter(func(n): return n > 0)
			var new_ax_pos: Guidot_Y_Axis_Canvas.AxisPosition
			
			# Since the y-axis drawing offset is handled by figuring out its offset based on its width and axis position
			# it is important that the axis is in incremental order such that secondary axis needs to exist if we want to create the
			# third axis
			# Refer to the function: calculate_offset_from_plot_frame() to see how the axis offsets are handled
			if (ax_pos < 0 and not all_left_axis.is_empty()):
				if (abs(int(ax_pos - all_left_axis.min())) > 1):
					new_ax_pos = all_left_axis.min() - 1
					Guidot_Log.gd_log(Guidot_Log.Log_Level.WARNING, self._tag, ["Reshifting the axis ID from ", ax_pos, " to ", new_ax_pos])
					ax_pos = new_ax_pos
			# If there are no axis on the left side, then force it to be primary left
			elif (ax_pos < 0 and all_left_axis.is_empty()):
				new_ax_pos = Guidot_Y_Axis_Canvas.AxisPosition.PRIMARY_LEFT
				Guidot_Log.gd_log(Guidot_Log.Log_Level.WARNING, self._tag, ["Reshifting the axis ID from ", ax_pos, " to ", new_ax_pos])
				ax_pos = new_ax_pos

			elif (ax_pos > 0 and not all_right_axis.is_empty()):
				if (abs(int(ax_pos - all_right_axis.max())) > 1):
					new_ax_pos = all_right_axis.max() + 1
					Guidot_Log.gd_log(Guidot_Log.Log_Level.WARNING, self._tag, ["Reshifting the axis ID from ", ax_pos, " to ", new_ax_pos])
					ax_pos = new_ax_pos
			# If there are no axis on the right side, then force it to be primary right
			elif (ax_pos > 0 and all_right_axis.is_empty()):
				new_ax_pos = Guidot_Y_Axis_Canvas.AxisPosition.PRIMARY_RIGHT
				Guidot_Log.gd_log(Guidot_Log.Log_Level.WARNING, self._tag, ["Reshifting the axis ID from ", ax_pos, " to ", new_ax_pos])
				ax_pos = new_ax_pos
		
		ax1.init_axis(self._parent_node, ax_pos, axis_range, true)
		self._axis_manager[ax_pos] = ax1
		return ax_pos

	func remove_axis_handler(ax_id: AxisHandler) -> bool:
		if (not self._axis_manager.erase(ax_id)):
			Guidot_Log.gd_log(Guidot_Log.Log_Level.WARNING, self._tag, ["Axis Handler of ID ", ax_id, " does not exist"])
			return false
		return true

	func remove_all_axis_handler() -> bool:
		# This step is to ensure that all y-axis node are queued free, before we release the resource
		# If this step is not done, if we remove the resource - clearing the dictionary consisting of the AxisHandler (RefCounted object)
		# prior to deleting the node, the y-axis node will remain in the axis
		# node anymore.
		for ax_pos in self._axis_manager.keys():
			self._axis_manager[ax_pos].get_axis_node().queue_free()
		self._axis_manager.clear()
		return true

	func get_axis_manager_dict() -> Dictionary:
		return self._axis_manager

	# The keys hold the axis ID which can easily help us identify which axis already exist
	func get_available_axis_handler() -> Array:
		return self._axis_manager.values()

	# Returns Array[Guidot_Y_Axis_Canvas.AxisPosition]
	func get_available_axis_pos() -> Array[int]:
		# Extract available axis positions from the axis manager
		var available_axes: Array[int] = []
		for axis_handler in self.get_available_axis_handler():
			available_axes.append(axis_handler.get_axis_id())
		return available_axes

	# Returns null if the requested axis handler does not exist	
	func get_axis_handler(ax_pos: Guidot_Y_Axis_Canvas.AxisPosition) -> AxisHandler:
		# TODO: Ensure the axis exist
		if (not self.has_axis_handler(ax_pos)):
			return null
		return self._axis_manager[ax_pos]

	func has_axis_handler(ax_pos: Guidot_Y_Axis_Canvas.AxisPosition) -> bool:
		return self._axis_manager.has(ax_pos)

	func delete_axis_handler(ax_pos: Guidot_Y_Axis_Canvas.AxisPosition) -> bool:
		return true

	# This function returns the number of axis that is on the left and right side of the graph
	# It will return Vector2(n_left_axis, n_right_axis)
	func get_axis_count() -> Vector2:
		var count: Vector2
		for i in self._axis_manager.keys():
			if (i < 0):
				count.x += 1
			else:
				count.y += 1
		return count

# Will handle the creation of all of the y-axis
@onready var _y_axis_manager: AxisManager = AxisManager.new()

# Toggle switch
@onready var _toggle_nerd_stats: bool = false
@onready var _is_pause: bool = false

@export_group("X-Axis")
@export var t_axis_min: float = 1
@export var t_axis_max: float = 30
@export var x_number_of_ticks: int = 10

@export_group("Plot")
@export var plot_update_rate_hz: float = 60.0

@export_group("Y-Axis")
@export var y_axis_min: float = 0
@export var y_axis_max: float = 2000
@export var y_number_of_ticks: int = 10

@onready var _current_graph_mode: Graph_Buffer_Mode = Graph_Buffer_Mode.REALTIME
@onready var _prev_graph_mode: Graph_Buffer_Mode = self._current_graph_mode

# Axis count is limited up to Guidot_Y_Axis_Canvas._max_axis_num
@onready var _curr_y_axis_count: int = 1

@onready var fps_last_update_ms: float = Time.get_ticks_msec()

# Helper tool
var debug_panel: Guidot_Debug_Panel

# Final debug trace signals are used to encapsulate all of the debug tace signals of each of our components
@onready var final_debug_trace_signals: Dictionary = {}

#### SIGNAL TRACE #####
@onready var mouse_pressed_flag: bool = false

func update_debug_info() -> void:
	self.debug_signals_to_trace = {
		"Graph: mouse in": self._mouse_in,
		"Graph: in focus": self._is_in_focus,
		"Graph: mouse filter": self.get_mouse_filter(),
	}

func _update_final_debug_trace() -> void:
	self.update_debug_info()
	plot_node.update_debug_info()
	t_axis_node.update_debug_info()
	self.final_debug_trace_signals.clear()

	# TODO (Khalid): At the moment, I am leaving this hard-coded because this isn't really a user feature
	# Only developer should be using this
	var child_array: Array[Guidot_Common] = [self, plot_node, t_axis_node] 

	for child in child_array:
		for debug_signal in child.debug_signals_to_trace:
			self.final_debug_trace_signals[debug_signal] = child.debug_signals_to_trace[debug_signal]

### HELPER FUNCTIONS #####
@onready var t_axis_lim_signal: int = 0 
@onready var y_axis_lim_signal: int = 0 
@onready var data_received_signal: int = 0 

func get_last_data_point() -> Vector2:
	var tmp: Vector2 = Vector2()
	if (self._get_data() == null):
		return tmp
	elif (self._get_data().size() == 0):
		return tmp
	else:
		tmp = self._get_data()[-1]
	return tmp

func get_current_data_fetch_mode_str() -> String:
	return plot_node.data_fetching_mode_str[plot_node.data_fetching_mode]

##########################

func get_buffer_mode_str(buf_mode: Graph_Buffer_Mode) -> String:
	match buf_mode:
		Graph_Buffer_Mode.FIXED:
			return "Fixed"
		Graph_Buffer_Mode.REALTIME:
			return "Realtime"
		_:
			return "Not Implemented"

# NOTE: This whole thing is a mess, and just me trying to do stupid fix. Not the most optimal solution, but at least
# no visible bugs for now. I will need to tackle the bug some other time
func _setup_plot_node() -> void:

	# Number of left and right y-axis components
	var n_y_axis: Vector2 = self._y_axis_manager.get_axis_count()
	var n_left_yax_comp: float = n_y_axis.x
	var n_right_yax_comp: float = n_y_axis.y
	# Temporary to handle margin
	var header_margin: float = 0.075

	# Find the necessary offset relative to the graph area
	var plot_size_scaled: Vector2 = plot_node.norm_comp_size * self.size
	self.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_LEFT)
	var y_axis_width: float = clamp(0.075 * self.size.x, 0, 50)

	# Explicit offset calculation for better clarity
	var left_offset: float = n_left_yax_comp * y_axis_width
	var button_width: float = self._setting_button.size.x if self._setting_button.size.x > 0 else 30
	var right_padding: float = 50 + 4.0
	var right_offset: float
	if (n_right_yax_comp == 0):
		right_offset = self.size.x - right_padding
	else:
		var right_ax_width = n_right_yax_comp * y_axis_width
		right_offset = self.size.x - right_ax_width - right_padding
	var top_offset: int = int(header_margin * self.size.y)
	var bottom_offset: int = int(self.size.y - t_axis_node.norm_comp_size.y * self.size.y)

	plot_node.init_plot(Guidot_Utils.get_color("gd_black"))
	plot_node.setup_plot_frame_offset(left_offset, right_offset, top_offset, bottom_offset)

func _init_plot_node():
	self._setup_plot_node()
	self.add_child(plot_node)

func _setup_axis(axis_node: Guidot_Axis_Canvas, axis_id: int, axis_name: String, axis_color: Color, axis_range: Vector2) -> void:
	self._init_axis(axis_node, axis_name, axis_color, axis_range)
	axis_node.set_axis_id(axis_id)
	axis_node.setup_axis_range(axis_range.x, axis_range.y)
	axis_node.calculate_offset_from_plot_frame(self, plot_node)

func _init_axis(axis_node: Guidot_Axis_Canvas, axis_name: String, axis_color: Color, axis_range: Vector2) -> void:
	axis_node.setup_axis_node(axis_name, axis_color)
	axis_node.setup_axis_range(axis_range.x, axis_range.y)

func _init_t_axis_node():
	self._init_axis(t_axis_node, "t_axis", Guidot_Utils.get_color("gd_black"), Vector2(t_axis_min, t_axis_max))
	self.add_child(t_axis_node)

func setup_font() -> void:
	pass

func _init_font() -> void:
	setup_font()

func _register_hotkeys() -> void:
	# Input action mapping
	Guidot_Utils.add_action_with_keycode("help", KEY_H)
	Guidot_Utils.add_action_with_keycode("nerd_stats", KEY_TAB)
	Guidot_Utils.add_action_with_keycode("pause", KEY_SPACE)

func _request_buffer_mode() -> void:
	if (self._guidot_server == null):
		self.log(LOG_WARNING, ["No server has been selected. Please"])
	else:
		self._current_graph_mode = self._guidot_server.get_graph_buffer_mode()
		self.log(LOG_INFO, ["Current buffer mode: ", self.get_buffer_mode_str(self._current_graph_mode)])

# TODO (Khalid): Make this more fool proof, add checks, or even potentially allow the user to be able to user their own server
# Check if any server actually exist
func init_server() -> void:
	pass

func _setup_graph_client() -> void:
	self.clip_contents = true
	self.size = default_window_size
	self.color = default_window_color
	self._component_tag = "DISPLAY"

func _register_graph_client() -> void:
	self.name = Guidot_Utils.generate_unique_name(self, Guidot_Common._graph_group_name)
	self.add_to_group(self._graph_group_name)

func _on_data_subscribed(subscribe: bool, channel_name: String) -> void:

	self.log(LOG_DEBUG, [subscribe, " and ", channel_name])
	
	if (subscribe):
		self._selected_channels_name.append(channel_name)
		self.log(LOG_DEBUG, [self._selected_channels_name])
		# Populate selected labels
		var ax_id_str: String
		var curr_axis_to_data_map: Dictionary = self._y_axis_manager.get_data_to_axis_map()

		ax_id_str = "PRIMARY_LEFT"
		self._y_axis_manager.set_data_to_axis(self._guidot_server, channel_name, ax_id_str)
		self.refresh_y_axis()
	else:
		if (channel_name in self._selected_channels_name):
			self._selected_channels_name.erase(channel_name)

	self.plot_realtime_data()

func refresh_y_axis() -> void:
	for ax_handler in self._y_axis_manager.get_available_axis_handler():
		var ax_node: Guidot_Y_Axis_Canvas = ax_handler.get_axis_node()
		if ax_node != null:
			ax_node.queue_redraw()
	# Also refresh plot and overall display
	self.plot_realtime_data()
	if plot_node != null:
		plot_node.queue_redraw()
	self.queue_redraw()


func _on_wizard_axis_assignment(channel_name: String, axis_name_str: String) -> void:
	if self._y_axis_manager:
		self._y_axis_manager.set_data_to_axis(self._guidot_server, channel_name, axis_name_str)
		# Ensure axis labels update immediately (avoid needing to hover to trigger redraw)
		self.refresh_y_axis()

# Ensure that we can use this with other nodes, so we don't have to hard code the names when used in different places
const _graph_in_focus_callback_name: String = "which_graph_in_focus"
func which_graph_in_focus(graph_name: String) -> void:
	var show_settings: bool = (self.name == graph_name)

	self.log(LOG_DEBUG, ["Settings show status for", self.name, "is", show_settings])
	if (self.name == graph_name):
		self._graph_selected = true
		# Guidot_Wizard upon ready will insert itself into its own group name
		# There should only be one guidot wizard, so the first node in this array should be the guidot wizard itself
		self._guidot_wizard = self.get_tree().get_nodes_in_group(Guidot_Common._wizard_group_name)[0]
		self._guidot_wizard.config_tree_configured.connect(self._apply_user_config)
		self._guidot_wizard.subscribe_to_data.connect(self._on_data_subscribed)
		self._guidot_wizard.axis_assignment_changed.connect(self._on_wizard_axis_assignment)
		self.get_tree().call_group(Guidot_Common._wizard_group_name, "update_config_tree", self._config_tree, self._selected_channels_name)
		self._update_axis_selection()
		self.ui_action_request.emit(Guidot_Common.UI_Action.FOCUS_MODE)
	elif (self.name != graph_name):
		# We need to disconnect the signal since we don't want to continuously add the callback multiple times if it were
		# to be selected again
		self._graph_selected = false
		if (self._guidot_wizard != null):
			print(self._guidot_wizard.is_connected("config_tree_configured", self._apply_user_config))
			self._guidot_wizard.config_tree_configured.disconnect(self._apply_user_config)
			self._guidot_wizard.subscribe_to_data.disconnect(self._on_data_subscribed)
			self._guidot_wizard.axis_assignment_changed.disconnect(self._on_wizard_axis_assignment)
		self.ui_action_request.emit(Guidot_Common.UI_Action.REMOVE_FOCUS)

func _get_data() -> PackedVector2Array:

	if (self._curr_data_str == null):
		return PackedVector2Array()
	else:
		return self._guidot_server.query_data_with_channel_name(self._curr_data_str)

func _get_line_color() -> Color:
	return self._guidot_server.query_data_line_color(self._curr_data_str)

func _on_changes_applied(server_config_array: Array[Guidot_Server_Config]):

	if (server_config_array.is_empty()):
		self.log(LOG_WARNING, ["No server has been selected. Please use the Add Server button to subscribe to any available server."])
	else:
		
		# TODO (Khalid): At the moment, I am only using the first server that is selected
		for i in len(server_config_array):
			self._guidot_server = server_config_array[0].get_selected_server()
			self._request_buffer_mode()

	
			if (server_config_array[0].get_selected_data().is_empty()):
				self.log(LOG_WARNING, ["Please select data that you wish to subscribe to: ", server_config_array[0].get_all_data_options()])
				self._selected_channels_name = []
				# Pass an empty array to remove all of the channels from the axis
				self._y_axis_manager.remove_data_from_axis([])
			else:
				self._selected_channels_name = server_config_array[0].get_selected_data()

				var gd_node_array: Array[Guidot_Data] = []
				for chan_name in self._selected_channels_name:
					gd_node_array.append(self._guidot_server.get_node_id_with_channel_name(chan_name))

				self._y_axis_manager.remove_data_from_axis(gd_node_array)

	self.resized.emit()

func _on_y_axis_changes_applied(n_axis) -> void:
	var n_left: int = n_axis[0]
	var n_right: int = n_axis[1]

	# Disconnect the pre-existing primary axis from handling the horizontal axis drawing
	# This will get re-assigned once all of the axis has been initialized again
	var paxis_handler: AxisHandler = self._y_axis_manager.get_axis_manager_dict()[Guidot_Y_Axis_Canvas.AxisPosition.PRIMARY_LEFT]
	var primary_axis: Guidot_Y_Axis_Canvas = paxis_handler.get_axis_node()
	primary_axis.axis_limit_changed.disconnect(_on_y_axis_changed)

	# Instead of trying to dynamically find existing axis handler and then try and fit the remaining axis as per requested by the
	# user, simply delete all y-axis, and create new instances of it. This is not too computationally expensive as this operation
	# should only occur only when the user wishes to add more y-axis
	self._y_axis_manager.remove_all_axis_handler()

	for i in range(1, n_left + 1):
		self._y_axis_manager.add_axis_handler(-i)

	for i in range(1, n_right + 1):
		self._y_axis_manager.add_axis_handler(i)

	# Renew the primary axis connection for drawing the horizontal axis
	paxis_handler = self._y_axis_manager.get_axis_manager_dict()[Guidot_Y_Axis_Canvas.AxisPosition.PRIMARY_LEFT]
	primary_axis = paxis_handler.get_axis_node()
	primary_axis.axis_limit_changed.connect(_on_y_axis_changed.bind(primary_axis))
	
	self._init_font()

	self._setting_button.size = Vector2(30, 30)
	self._setting_button.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_LEFT)
	self._setting_button.position = Vector2(self.size.x - self._setting_button.size.x, 0)

	var available_axis: Array = self._y_axis_manager.get_axis_manager_dict().keys()

	# If in the case that the number of axis had been resized down, force the data that uses the non-existent axis to revert back to
	# PRIMARY_LEFT
	var curr_data_to_axis_map: Dictionary = self._y_axis_manager.get_data_to_axis_map()
	for data_node in curr_data_to_axis_map.keys():
		self._y_axis_manager.set_data_node_to_axis(data_node, curr_data_to_axis_map[data_node])

	# This might be redundant as the one above, but fuck it, I am tired. This is an easy fix to make sure I dont fuck up when the number
	# of axis decreases
	# Please note that since this function also calls, set_axis_range(), it will inherently trigger axis_limit_changed signal which will
	# then queue a redraw (this is not optimal, but I will fix this if I see any form of bottleneck due to this implementation). Since
	# I am assuming the user would rarely trigger any sort of change in the number of axis, this should be fine and would not cost any sort
	# of performance.
	for data_node in self._y_axis_manager.get_data_to_axis_map().keys():
		var curr_ax_id_str: String = self._y_axis_manager.get_data_to_axis_map()[data_node]
		if (not Guidot_Y_Axis_Canvas.AxisPosition[curr_ax_id_str] in available_axis):
			self._y_axis_manager.get_data_to_axis_map()[data_node] = "PRIMARY_LEFT"
		else:
			var axis_node: AxisHandler = self._y_axis_manager.get_axis_manager_dict()[Guidot_Y_Axis_Canvas.AxisPosition[curr_ax_id_str]]
			axis_node.set_axis_range(data_node.get_min_max())
	
	# Trigger the resized signal so that we redraw the newly configured axis
	self.resized.emit()
	self._y_axis_manager.updated.emit()

func get_y_axis_manager() -> AxisManager:
	return self._y_axis_manager

func _on_plot_drag_requested(delta_pos: Vector2):

	# delta_pixel is positive in the right and down direction
	var delta_pixel: Vector2 = delta_pos
	var plot_frame_size: Vector2 = self.plot_node.size
	var pix_motion_ratio: Vector2 = delta_pixel / plot_frame_size

	for ax_handler in self._y_axis_manager.get_axis_manager_dict().values():
		var delta_y: float = ax_handler.get_axis_diff() 
		var y_increment: float = pix_motion_ratio.y * delta_y
		var y_axis_range: Vector2 = ax_handler.get_axis_range()
		var new_y_range: Vector2 = Vector2(y_axis_range.x + y_increment, y_axis_range.y + y_increment)
		ax_handler.set_axis_range(new_y_range, false)

	var delta_t: float = self.t_axis_node.axis_diff()
	var t_increment: float = pix_motion_ratio.x * delta_t
	var t_axis_range: Vector2 = self.t_axis_node.get_axis_range()
	# This needs to be substracted since the delta pixel would produce positive result when going to the right, and if
	# user wants to drag right, the time axis would move backwards
	self.t_axis_node.setup_axis_range(self.t_axis_node.min_val - t_increment, self.t_axis_node.max_val - t_increment, true)

func _on_mouse_wheel_zoom_requested(mouse_button: MouseButton, mouse_ratio_pos: Vector2):
	
	var zoom_factor: float = 1.0001
	var r1: float = 0.5
	var r2: float = 0.5

	var tuned_ratio: float = 0.1

	var left_weight: float = mouse_ratio_pos.x
	var right_weight: float = (1 - left_weight)

	var top_weight: float = mouse_ratio_pos.y
	var bottom_weight: float = (1 - top_weight)

	for ax_handler in self._y_axis_manager.get_axis_manager_dict().values():
		var y_axis_range: Vector2 = ax_handler.get_axis_range()
		var y_axis_centre: float = abs(y_axis_range.x + y_axis_range.y) / 2.0
		var new_y_range: float
		var calc_zoom_range: Vector2

		if (mouse_button == MouseButton.MOUSE_BUTTON_WHEEL_UP):
			new_y_range = abs(y_axis_range.y - y_axis_range.x) / zoom_factor
			calc_zoom_range = Vector2(y_axis_range.x + new_y_range * bottom_weight * tuned_ratio, y_axis_range.y - new_y_range * top_weight * tuned_ratio)
			ax_handler.set_axis_range(calc_zoom_range, false)
		if (mouse_button == MouseButton.MOUSE_BUTTON_WHEEL_DOWN):
			new_y_range = abs(y_axis_range.y - y_axis_range.x) * zoom_factor
			calc_zoom_range = Vector2(y_axis_range.x - new_y_range * bottom_weight * tuned_ratio, y_axis_range.y + new_y_range * top_weight * tuned_ratio)
			ax_handler.set_axis_range(calc_zoom_range, false)

	var t_axis_range: Vector2 = self.t_axis_node.get_axis_range()
	var t_axis_centre: float = abs(t_axis_range.x + t_axis_range.y) / 2.0

	if (mouse_button == MouseButton.MOUSE_BUTTON_WHEEL_UP):
		var new_range: float = abs(t_axis_range.y - t_axis_range.x) / zoom_factor
		t_axis_node.setup_axis_range(t_axis_range.x + new_range * left_weight * tuned_ratio, t_axis_range.y - new_range * right_weight * tuned_ratio)
	elif (mouse_button == MouseButton.MOUSE_BUTTON_WHEEL_DOWN):
		var new_range: float = abs(t_axis_range.y - t_axis_range.x) * zoom_factor
		t_axis_node.setup_axis_range(t_axis_range.x - new_range * left_weight * tuned_ratio, t_axis_range.y + new_range * right_weight * tuned_ratio)

func resize_button_icon(button_icon: Texture2D) -> Texture2D:
	var resized_img: Image = button_icon.get_image()
	resized_img.resize(30, 30)
	var resized_icon = ImageTexture.create_from_image(resized_img)
	return resized_icon

func setup_button(graph_button: Button, icon: Texture2D, n_row: int, button_cb: Callable, tooltip: String = ""):
	graph_button.size = Vector2(30, 30)
	var resized_icon: Texture2D = self.resize_button_icon(icon)

	var empty_stylebox: StyleBoxEmpty = StyleBoxEmpty.new()

	graph_button.add_theme_stylebox_override("normal", empty_stylebox)
	graph_button.set_button_icon(resized_icon)
	graph_button.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_LEFT)
	graph_button.tooltip_text = tooltip
	graph_button.position = Vector2(self.size.x - graph_button.size.x, n_row * graph_button.size.y)
	graph_button.pressed.connect(button_cb)
	self.add_child(graph_button)

func _setup_all_ui_button():

	# Had to do it separately
	self._pause_icon = self.resize_button_icon(self._pause_icon)
	self._play_icon = self.resize_button_icon(self._play_icon)

	self.setup_button(self._setting_button, self._setting_icon, 0, self._on_setting_pressed, "Settings")
	self.setup_button(self._pause_button, self._pause_icon, 1, self._on_pause_pressed, "Pause the realtime graph")
	self.setup_button(self._edit_button, self._edit_icon, 2, self._on_edit_pressed, "Edit mode")
	self.setup_button(self._cursor_button, self._cursor_icon, 3, self._on_cursor_pressed, "Toggle cursor")
	self.setup_button(self._toggle_graph_button, self._toggle_graph_icon, 4, self._on_toggle_graph_pressed, "Toggle graph mode")
	self.setup_button(self._hide_graph_button, self._hide_graph_icon, 5, self._on_hide_graph_pressed, "Hide graph")
	self.setup_button(self._toggle_hotkey_button, self._toggle_hotkey_icon, 6, self._on_toggle_hotkey_pressed, "Enable/Disable hotkeys")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	self._setup_graph_client()
	self._register_graph_client()

	self._y_axis_manager.init_axis_manager(self)
	var paxis_handler: AxisHandler = self._y_axis_manager.get_axis_manager_dict()[Guidot_Y_Axis_Canvas.AxisPosition.PRIMARY_LEFT]
	var primary_axis: Guidot_Y_Axis_Canvas = paxis_handler.get_axis_node()
	primary_axis.axis_limit_changed.connect(_on_y_axis_changed.bind(primary_axis))

	# X/Y axis rectangle anchor offset calculation depends on the plot node anchor offset maths
	# Hence, plot node needs to be ran first before we run the axis node init
	self._init_t_axis_node()
	
	# Add child node for the graph
	self._init_plot_node()
	self.plot_node.register_parent_node(self)
	self.plot_node.zoom_requested.connect(self._on_zoom_requested)
	self.plot_node.plot_drag_requested.connect(self._on_plot_drag_requested)
	self.plot_node.mouse_wheel_zoom_requested.connect(self._on_mouse_wheel_zoom_requested)
	
	self._init_font()

	self._setup_all_ui_button()

	plot_node.update_x_ticks_properties(t_axis_node.n_steps, t_axis_node.ticks_pos)

	##########################
	#         SIGNAL         #
	##########################

	# Axis node signal
	t_axis_node.axis_limit_changed.connect(_on_t_axis_changed)

	plot_node.focus_requested.connect(_on_focus_requested)
	
	# Self node signal
	self.resized.connect(_on_display_frame_resized)
	
	# Use the guidot common mouse entered implementation
	self.mouse_entered.connect(self._on_mouse_entered)
	self.mouse_exited.connect(self._on_mouse_exited)

	self._register_hotkeys()
	
	debug_panel = Guidot_Debug_Panel.new()
	add_child(debug_panel)

	# This needs to be overriden after the debug panel is added as a child to the graph
	self._update_final_debug_trace()
	debug_panel.override_guidot_debug_info(self.final_debug_trace_signals)

	self._initialized = true
	self._on_graph_opacity_changed(1.0)

	self.log(LOG_INFO, ["Time series graph initialized"])

	queue_redraw()

# TODO: Implement this with error detection
func set_window_color(color: Color) -> void:
	self.color = color

func _on_graph_opacity_changed(alpha: float) -> void:

	# This allows us to finely control the opacity of our graphs and each of its components
	var a: float = clamp(alpha, 0.0, 1.0)
	var modulated_color: Color = Color(1.0, 1.0, 1.0, a)
	var current_color = self.color
	current_color.a = a
	self.color = current_color
	# self.set_self_modulate(modulated_color)
	
	# For the axis, we still want to see the data being plotted, so at minimum, an alpha of 0.3
	# would still allow you to see the plots nicely
	if (self._curr_ui_mode == Guidot_Time_Series_Graph.UI_Mode.DATA_DISPLAY):
		a = clamp(alpha, 0.1, 1.0)
	current_color.a = a 
	modulated_color = Color(1.0, 1.0, 1.0, a)
	# self.plot_node.set_self_modulate(modulated_color)
	# self.t_axis_node.set_self_modulate(modulated_color)
	self.color = current_color
	self.plot_node.color = color
	self.t_axis_node.color = color

	for ax_handler in self._y_axis_manager.get_available_axis_handler():
		ax_handler.set_axis_modulation(current_color)

	queue_redraw()

func _draw():
	# Data line drawing is handled inside the _draw function of plot_node
	t_axis_node.draw_axis()

func plot_realtime_data() -> void:
	
	self._guidot_server = self.get_tree().get_nodes_in_group(Guidot_Common._server_group_name)[0]

	if (self._guidot_server != null):

		var selected_gd_data: Dictionary = {}

		for channel_name in self._selected_channels_name:
			var gd_data: Guidot_Data = self._guidot_server.get_node_id_with_channel_name(channel_name)
			var channel_data_points: PackedVector2Array = self._guidot_server.query_data_with_channel_name(channel_name)
			selected_gd_data[gd_data] = channel_data_points

		self.plot_node.plot_multiple_data(selected_gd_data, self._y_axis_manager, Vector2(t_axis_min, t_axis_max))

func _on_display_frame_resized() -> void:

	self._setup_plot_node()
	self.log(LOG_DEBUG, ["The number of available axis handler is: ", len(self._y_axis_manager.get_available_axis_handler())])
	for axis_handler in self._y_axis_manager.get_available_axis_handler():
		self._setup_axis(axis_handler.get_axis_node(), axis_handler.get_axis_id(), "y_axis1", self.color, \
			axis_handler.get_axis_range()) 
	# Only reposition the t-axis — do not call setup_axis_range() here because
	# that would force the axis into FIXED mode, overriding SLIDING_WINDOW mode.
	t_axis_node.calculate_offset_from_plot_frame(self, plot_node)
	
	# Ensure the UI buttons are always at the top right during resizing
	var i: int = 0
	for ui_button in self._ui_buttons:
		ui_button.position = Vector2(self.size.x - ui_button.size.x, i * ui_button.size.y)
		i += 1

	self.log(LOG_DEBUG, ["Display frame resized"])

########################################
#    SIGNAL CALLBACK IMPLEMENTATION    #
########################################
func _on_data_received() -> void:
	if (not self._is_pause):
		self.data_received_signal += 1
		t_axis_min = t_axis_node.min_val
		t_axis_max = t_axis_node.max_val
		# REALTIME mode: _process drives redraws at plot_update_rate_hz — don't
		# redraw here or every incoming sample bypasses the rate cap.
		# FIXED mode: redraw immediately so a static window reflects new data.
		if _current_graph_mode == Graph_Buffer_Mode.FIXED:
			self.plot_realtime_data()
			queue_redraw()

func _on_focus_requested() -> void:
	self._is_in_focus = !self._is_in_focus
	self.parent_focus_requested.emit()

func _on_zoom_requested(pixel_rect: Rect2) -> void:
	var comp_size: Vector2 = plot_node.get_component_size()

	var old_t_min := t_axis_min
	var old_t_max := t_axis_max
	var new_t_min := remap(pixel_rect.position.x, 0, comp_size.x, old_t_min, old_t_max)
	var new_t_max := remap(pixel_rect.end.x, 0, comp_size.x, old_t_min, old_t_max)
	# Drive through setup_axis_range so axis_limit_changed fires and ticks recalculate
	t_axis_node.setup_axis_range(new_t_min, new_t_max)

	for axis_handler in self._y_axis_manager.get_available_axis_handler():
		var curr_range: Vector2 = axis_handler.get_axis_range()
		# y pixel is inverted: 0=top=data max, comp_size.y=bottom=data min
		var new_y_min := remap(pixel_rect.end.y, comp_size.y, 0, curr_range.x, curr_range.y)
		var new_y_max := remap(pixel_rect.position.y, comp_size.y, 0, curr_range.x, curr_range.y)
		axis_handler.set_axis_range(Vector2(new_y_min, new_y_max))

func _on_t_axis_changed() -> void:
	self.t_axis_lim_signal += 1
	t_axis_min = t_axis_node.min_val
	t_axis_max = t_axis_node.max_val
	plot_node.update_x_ticks_properties(t_axis_node.n_steps, t_axis_node.ticks_pos)
	self.plot_realtime_data()

func update_ui_mode_state(ui_mode: Guidot_Time_Series_Graph.UI_Mode):

	self.set_ui_mode(ui_mode)
	self.plot_node.set_ui_mode(ui_mode)
	
	if (self._curr_ui_mode == Guidot_Time_Series_Graph.UI_Mode.EDIT):
		self._prev_opacity_setting = self.get_self_modulate().a
	elif (self._prev_ui_mode == Guidot_Time_Series_Graph.UI_Mode.EDIT and self._curr_ui_mode == Guidot_Time_Series_Graph.UI_Mode.DATA_DISPLAY):
		self.log(LOG_DEBUG, ["Previous opacity is ", self._prev_opacity_setting])
		self._on_graph_opacity_changed(self._prev_opacity_setting)
	else:
		pass


# This needs to be tied to the primary axis to draw the horizontal grids
func _on_y_axis_changed(primary_axis: Guidot_Y_Axis_Canvas) -> void:
	self.y_axis_lim_signal += 1
	plot_node.update_y_ticks_properties(primary_axis.n_steps, primary_axis.ticks_pos)
	# plot_node.update_y_ticks_properties(n_steps, ticks_pos)

func plot_fixedtime_data():
	pass

func _update_buffer_mode(new_buff_mode: Graph_Buffer_Mode):
	# self._config_tree[_GBS.global_key][self._graph_buffer_mode_key][_GBS.value_key]  = new_buff_mode
	self._config_tree[_GBS.local_key][self._graph_buffer_mode_key][_GBS.value_key]  = new_buff_mode
	self._current_graph_mode = new_buff_mode
	self.plot_node._curr_graph_mode = new_buff_mode

func _input(event: InputEvent) -> void:

	if event is InputEventMouseButton:
		
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				# TODO (Khalid): At the moment, this does not work because if we click on the plot,
				# the display also captures this signal, resulting in "double emit focus" signal generated
				# self._emit_focus_requested_signal()
				if (self._is_in_focus):
					plot_node._is_in_focus = false
				pass

	# For hotkeys
	# if (Input.is_action_just_pressed("nerd_stats")):
	# 	self._toggle_nerd_stats = !self._toggle_nerd_stats
	# 	self.log(LOG_DEBUG, ["Toggle for nerd stats:", self._toggle_nerd_stats])
	# 	self.log(LOG_INFO, ["Displaying nerd stats"])

	# 	if (self._toggle_nerd_stats):
	# 		var curr_mouse_pos: Vector2 = self.get_viewport().get_mouse_position()
	# 		debug_panel.set_position(curr_mouse_pos)
	# 		debug_panel.show()
	# 	else:
	# 		debug_panel.hide()

	if event is InputEventKey and event.pressed:

		if (event.shift_pressed and event.keycode == KEY_H):
			if (not self.visible):
				self._on_hide_graph_pressed()
		elif (event.keycode == KEY_H):
			if (self.visible):
				self._on_hide_graph_pressed()

		if (event.keycode == KEY_G):
			self._on_toggle_graph_pressed()

		if (event.keycode == KEY_ESCAPE):
			self._on_setting_pressed(false)

func _set_mouse_filter_action():
	if (self._curr_ui_mode == Guidot_Time_Series_Graph.UI_Mode.EDIT or self._curr_ui_mode == Guidot_Time_Series_Graph.UI_Mode.SELECTED):
		self.set_mouse_filter(MOUSE_FILTER_IGNORE)
		self.plot_node.set_mouse_filter(MOUSE_FILTER_IGNORE)
		
		self._prev_graph_mode = self._current_graph_mode
		self._current_graph_mode = Graph_Buffer_Mode.PAUSE
	else:
		self.set_mouse_filter(MOUSE_FILTER_STOP)
		self.plot_node.set_mouse_filter(MOUSE_FILTER_STOP)
		self._current_graph_mode = self._prev_graph_mode

# Please note that if physics_process is used here, this will caused a lot of lag as the physics process
# will be consistent at the 60 Hz frame rate (or loop rate configured through the physics setting)
# If the physics_process is used here, the setup_axis_range() function in the realtime mode
# gets called consistently even when the fps is dropping. This causes the process function to get
# overloaded as it could not keep up with the constant update
func _process(delta: float) -> void:

	self._set_mouse_filter_action()
	self._move_display_process()

	var curr_ms: int = Time.get_ticks_msec()

	# This may seem to be a duplicate to the switch that comes after, but I'd rather have the graph node itself being the "master"
	# to pass what current state it is rather than using the output directly from the time axis node (Just my preference)
	match (self.t_axis_node.get_current_t_axis_mode()):
		self.t_axis_node.TAxisMode.FIXED:
			self._update_buffer_mode(Graph_Buffer_Mode.FIXED)
		self.t_axis_node.TAxisMode.SLIDING_WINDOW:
			self._update_buffer_mode(Graph_Buffer_Mode.REALTIME)

	match (self._curr_ui_mode):

		Guidot_Time_Series_Graph.UI_Mode.EDIT:
			# self._on_graph_opacity_changed(1.0)
			self.plot_node.queue_redraw()
		
		Guidot_Time_Series_Graph.UI_Mode.SELECTED:
			# self._on_graph_opacity_changed(1.0)
			self.plot_node.queue_redraw()

		# BUGFIX: When the user sets opacity during edit mode, the previous opacity setting is still held in place, which means that the opacity slider
		# does not have any effect until the user goes back to data display mode
		Guidot_Time_Series_Graph.UI_Mode.DATA_DISPLAY:

			match (self._current_graph_mode):

				# Fixed mode would still work despite no logic being in here is due to the power of callback in Godot.
				# It is rather annoying that everything is abstracted inside the callback, however, to trace how the graphs updates correctly
				# as per user input. See _axis_limit_changed() function. Everytime we update the axis limit, it will simply emit a signal that will
				# call plot_realtime_data() which basically plots data that is within the vicinity of the axis range
				Graph_Buffer_Mode.FIXED:
					pass

				Graph_Buffer_Mode.PAUSE:
					return
			
				# When handling real-time data, we want to be able to update the last tick to always be incrementing
				# based on the last value data it receives, but to make a smooth sliding window, we will have to
				# smoothly shift the ticks in between the min and max value
				# In principle, the min val should stay constant unless the user specifies any desired min axis value,
				# and the max axis value will keep moving
				Graph_Buffer_Mode.REALTIME:
					
					if (float(curr_ms - self.fps_last_update_ms) >= 1000.0 / plot_update_rate_hz):
						# If there is no data present at the moment, then we ignore it
						if (self._guidot_server != null):
							if true:
								if (not self._is_pause):
									# The way that I wish to implement this is by having the minimum and maximum t-axis to be always an
									# even number
									# TODO (Khalid): Allow the user to use external clock source, the way that this is currently implemented
									# is that the time series graph itself generates the clock, so if the user wish to plot and visualize
									# their data in realtime, they will have to use Time.get_ticks_msec() function to have the correct
									# scale. The external clock source would allow the time axis to be a lot more flexble in a sense that it can be
									# simply an increasing integer, or absolute or relative time etc.
									var curr_s: float = self._guidot_clock_node.get_current_time_s()
									t_axis_node.update_to_latest(curr_s)
									self.plot_realtime_data()
									queue_redraw()

						self.fps_last_update_ms = curr_ms

	if (not self._is_pause):
		self._update_final_debug_trace()
		self.debug_panel._guidot_debug_info = self.final_debug_trace_signals	
