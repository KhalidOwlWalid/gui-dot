extends Node

# @onready var guidot_utils = Guidot_Utils.new()
@onready var curr_t: float = 0
@onready var last_update_ms: int = Time.get_ticks_msec()
@onready var init_ms: int = Time.get_ticks_msec()
@onready var data_transmitted: bool = false

# dc - data client
@onready var _dc_mouse_cursor: Guidot_Data_Client = Guidot_Data_Client.new()
@onready var _godot_performance: Guidot_Data_Client = Guidot_Data_Client.new()
@onready var _mouse_x: Guidot_Data = Guidot_Data.new()
@onready var _mouse_y: Guidot_Data = Guidot_Data.new()
@onready var _test: Guidot_Data = Guidot_Data.new()
@onready var _test2: Guidot_Data = Guidot_Data.new()

signal data_received

# func setup_data_client_util(client_node: Guidot_Data_Client, data_node: Guidot_Data, name: String, unit: String, \
# 	 description: String, min: float, max: float, color: String = "red") -> void:
# 	data_node.setup_properties(name, unit, description, min, max, color)
# 	client_node.register_data_channel(data_node)
# 	client_node.update_server()

func _ready() -> void:
	print("Mavlink node is now ready")

	# Necessary for guidot data client to work
	self.add_child(self._dc_mouse_cursor)
	self.add_child(self._godot_performance)

	# self.setup_data_client_util(self._dc_mouse_cursor, self._mouse_x, "mouse_x", "None", "Example", 0, 2000, "white")
	# self.setup_data_client_util(self._dc_mouse_cursor, self._mouse_y, "mouse_y", "None", "Example", 0, 1100, "red")
	Guidot_Utils.setup_data_client_util(self._dc_mouse_cursor, self._mouse_x, "mouse_x", "None", "Example", 0, 2000, "white")
	Guidot_Utils.setup_data_client_util(self._dc_mouse_cursor, self._mouse_y, "mouse_y", "None", "Example", 0, 1100, "red")
	
func _mouse_cursor_data(delta: float) -> void:
	var curr_ms: int = Time.get_ticks_msec()
	var curr_s: float = float(curr_ms)/1000

	if (curr_ms - last_update_ms > 10):
		var relative_ms: int = curr_ms - init_ms
		var curr_mouse_pos = self.get_viewport().get_mouse_position()

		self._dc_mouse_cursor.add_data_point(self._mouse_x, curr_mouse_pos.x)
		self._dc_mouse_cursor.add_data_point(self._mouse_y, curr_mouse_pos.y)
		last_update_ms = Time.get_ticks_msec()

func _physics_process(delta: float) -> void:
	_mouse_cursor_data(delta)	
