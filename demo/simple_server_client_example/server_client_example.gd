extends Node

@onready var curr_t: float = 0
@onready var last_update_ms: int = Time.get_ticks_msec()
@onready var fps_last_update_ms: int = Time.get_ticks_msec()
@onready var custom_last_update_ms: int = Time.get_ticks_msec()
@onready var init_ms: int = Time.get_ticks_msec()
@onready var data_transmitted: bool = false

@onready var _dc_mouse_cursor: Guidot_Data_Source = Guidot_Data_Source.new()
@onready var _mouse_x: Guidot_Data = Guidot_Data.new()
@onready var _mouse_y: Guidot_Data = Guidot_Data.new()

@onready var _godot_performance: Guidot_Data_Source = Guidot_Data_Source.new()
@onready var _fps: Guidot_Data = Guidot_Data.new()
@onready var _physics_frame: Guidot_Data = Guidot_Data.new()

@onready var _custom_data: Guidot_Data_Source = Guidot_Data_Source.new()
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

	self.add_child(self._dc_mouse_cursor)
	self.add_child(self._godot_performance)
	self.add_child(self._custom_data)

	self._dc_mouse_cursor.set_custom_name("DC Mouse Cursor")
	self._mouse_x.setup_properties("mouse_x", "None", "Example", 0, 2000, 60, "white")
	self._mouse_y.setup_properties("mouse_y", "None", "Example", 0, 1100, 60, "red")
	var mouse_group := Guidot_Data_Group.new().setup("Position")
	mouse_group.add_channel(self._mouse_x).add_channel(self._mouse_y)
	Guidot_Utils.setup_data_group_util(self._dc_mouse_cursor, mouse_group)

	self._godot_performance.set_custom_name("Godot Performance")
	self._fps.setup_properties("fps", "fps", "Guidot FPS performance", 0, 150, 30, "yellow")
	self._physics_frame.setup_properties("physics_frame", "fps", "Guidot FPS performance", 0, 150, 30, "yellow")
	var perf_group := Guidot_Data_Group.new().setup("Metrics")
	perf_group.add_channel(self._fps).add_channel(self._physics_frame)
	Guidot_Utils.setup_data_group_util(self._godot_performance, perf_group)

	self._custom_data.set_custom_name("Custom Data")
	self._sin.setup_properties("sin", "m", "Sinusoidal wave", -1.1, 1.1, 30, "magenta")
	self._cos.setup_properties("cos", "m", "Cosine wave", -1.1, 1.1, 30, "cyan")
	var wave_group := Guidot_Data_Group.new().setup("Waveforms")
	wave_group.add_channel(self._sin).add_channel(self._cos)
	Guidot_Utils.setup_data_group_util(self._custom_data, wave_group)

func _mouse_cursor_data() -> void:
	var curr_ms: int = Time.get_ticks_msec()

	if (curr_ms - last_update_ms > 10):
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
	var update_freq_hz: float = 100.0
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
