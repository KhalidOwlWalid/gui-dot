extends Node

# @onready var guidot_utils = Guidot_Utils.new()
@onready var curr_t: float = 0
@onready var last_update_ms: int = Time.get_ticks_msec()
@onready var fps_last_update_ms: int = Time.get_ticks_msec()
@onready var init_ms: int = Time.get_ticks_msec()
@onready var data_transmitted: bool = false

# dc - data client
@onready var _dc_mouse_cursor: Guidot_Data_Client = Guidot_Data_Client.new()
@onready var _godot_performance: Guidot_Data_Client = Guidot_Data_Client.new()
@onready var _mouse_x: Guidot_Data = Guidot_Data.new()
@onready var _mouse_y: Guidot_Data = Guidot_Data.new()
@onready var _fps: Guidot_Data = Guidot_Data.new()


signal data_received

func _ready() -> void:
	print("Mavlink node is now ready")

	# Necessary for guidot data client to work
	self.add_child(self._dc_mouse_cursor)
	self.add_child(self._godot_performance)

	Guidot_Utils.setup_data_client_util(self._dc_mouse_cursor, self._mouse_x, "mouse_x", "None", "Example", 0, 2000, "white")
	Guidot_Utils.setup_data_client_util(self._dc_mouse_cursor, self._mouse_y, "mouse_y", "None", "Example", 0, 1100, "red")
	Guidot_Utils.setup_data_client_util(self._godot_performance, self._fps, "fps", "fps", "Guidot FPS performance", 0, 150, "yellow")
	
func _mouse_cursor_data() -> void:
	var curr_ms: int = Time.get_ticks_msec()
	var curr_s: float = float(curr_ms)/1000

	if (curr_ms - last_update_ms > 10):
		var relative_ms: int = curr_ms - init_ms
		var curr_mouse_pos = self.get_viewport().get_mouse_position()

		self._dc_mouse_cursor.add_data_point(self._mouse_x, curr_mouse_pos.x)
		self._dc_mouse_cursor.add_data_point(self._mouse_y, curr_mouse_pos.y)
		self._godot_performance.add_data_point(self._fps, Engine.get_frames_per_second())
		last_update_ms = Time.get_ticks_msec()

func _fps_data() -> void:
	var curr_ms: int = Time.get_ticks_msec()

	if (curr_ms - fps_last_update_ms > 100):
		self._godot_performance.add_data_point(self._fps, Engine.get_frames_per_second())
		fps_last_update_ms = Time.get_ticks_msec()

func _physics_process(_delta: float) -> void:
	_mouse_cursor_data()	
