extends Node

# @onready var guidot_utils = Guidot_Utils.new()
@onready var curr_t: float = 0
@onready var last_update_ms: int = Time.get_ticks_msec()
@onready var fps_last_update_ms: int = Time.get_ticks_msec()
@onready var custom_last_update_ms: int = Time.get_ticks_msec()
@onready var init_ms: int = Time.get_ticks_msec()
@onready var data_transmitted: bool = false

# dc - data client
@onready var _dc_mouse_cursor: Guidot_Data_Client = Guidot_Data_Client.new()
@onready var _mouse_x: Guidot_Data = Guidot_Data.new()
@onready var _mouse_y: Guidot_Data = Guidot_Data.new()

@onready var _godot_performance: Guidot_Data_Client = Guidot_Data_Client.new()
@onready var _fps: Guidot_Data = Guidot_Data.new()
@onready var _physics_frame: Guidot_Data = Guidot_Data.new()

@onready var _custom_data: Guidot_Data_Client = Guidot_Data_Client.new()
@onready var _sin: Guidot_Data = Guidot_Data.new()
@onready var _cos: Guidot_Data = Guidot_Data.new()

var thread: Thread
var mutex: Mutex
@onready var counter: int = 0


signal data_received

func _counter() -> void:
	mutex.lock()
	counter += 1
	mutex.unlock()
	pass

func _ready() -> void:
	print("Mavlink node is now ready")

	mutex = Mutex.new()
	thread = Thread.new()
	thread.start(_counter)

	# Necessary for guidot data client to work
	self.add_child(self._dc_mouse_cursor)
	self.add_child(self._godot_performance)
	self.add_child(self._custom_data)

	Guidot_Utils.setup_data_client_util(self._dc_mouse_cursor, self._mouse_x, "mouse_x", "None", "Example", 0, 2000, 60, "white")
	Guidot_Utils.setup_data_client_util(self._dc_mouse_cursor, self._mouse_y, "mouse_y", "None", "Example", 0, 1100, 60, "red")

	Guidot_Utils.setup_data_client_util(self._godot_performance, self._fps, "fps", "fps", "Guidot FPS performance", 0, 150, 30, "yellow")
	Guidot_Utils.setup_data_client_util(self._godot_performance, self._physics_frame, "physics_frame", "fps", "Guidot FPS performance", 0, 150, 30, "yellow")

	Guidot_Utils.setup_data_client_util(self._custom_data, self._sin, "sin", "m", "Sinusoidal wave", -1.1, 1.1, 30, "magenta")
	Guidot_Utils.setup_data_client_util(self._custom_data, self._cos, "cos", "m", "Cosine wave", -1.1, 1.1, 30, "cyan")
	
func _mouse_cursor_data() -> void:
	var curr_ms: int = Time.get_ticks_msec()
	var curr_s: float = float(curr_ms)/1000

	if (curr_ms - last_update_ms > 10):
		var relative_ms: int = curr_ms - init_ms
		var curr_mouse_pos = self.get_viewport().get_mouse_position()

		self._dc_mouse_cursor.add_data_point(self._mouse_x, curr_mouse_pos.x)
		self._dc_mouse_cursor.add_data_point(self._mouse_y, curr_mouse_pos.y)

		last_update_ms = Time.get_ticks_msec()

func _fps_data() -> void:
	var curr_ms: int = Time.get_ticks_msec()
	var update_freq_hz: float = 5
	var update_freq_ms: float = float(1/(update_freq_hz)) * 1000

	if (curr_ms - fps_last_update_ms > update_freq_ms):
		self._godot_performance.add_data_point(self._fps, Engine.get_frames_per_second())
		self._godot_performance.add_data_point(self._physics_frame, Engine.get_frames_drawn())
		fps_last_update_ms = Time.get_ticks_msec()

func _sin_cos() -> void:
	var curr_ms: int = Time.get_ticks_msec()
	var update_freq_hz: float = 60.0
	var update_freq_ms: float = float(1/(update_freq_hz)) * 1000

	if (curr_ms - self._sin._last_update_ms > update_freq_ms):
		self._custom_data.add_data_point(self._sin, sin(10 * (float(curr_ms)/1000.0)))
		self._custom_data.add_data_point(self._cos, cos(10 * float(curr_ms)/1000.0))
		self._sin._last_update_ms = Time.get_ticks_msec()

func test() -> void:
	print("Hello")

func _physics_process(_delta: float) -> void:
	_mouse_cursor_data()	
	_fps_data()
	_sin_cos()
