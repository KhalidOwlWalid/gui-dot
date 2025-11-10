extends Node

@onready var init: bool = false
@onready var last_update_ms: int = Time.get_ticks_msec()

var data_A: DataThreadHandler
var data_B: DataThreadHandler

class DataThreadHandler:
	var _thread: Thread
	var _mutex: Mutex
	var _semaphore: Semaphore
	var _callback_fn: Callable
	var _thread_id: int
	
	# Property
	var _last_update_ms: int
	var _update_rate_ms: int

	func init_data_thread_handler(thread_id: int, update_rate_ms: int, cb_func: Callable) -> void:
		self._thread = Thread.new()
		self._semaphore = Semaphore.new()
		self._mutex = Mutex.new()
		self._thread_id = thread_id
		self._update_rate_ms = update_rate_ms
		self._last_update_ms = Time.get_ticks_msec()
		self.register_callback(cb_func)

	func register_callback(cb_func: Callable):
		self._callback_fn = cb_func
		self._thread.start(self._callback_fn.bind(self._thread_id, self._semaphore))

	func post_semaphore() -> void:
		self._semaphore.post()

	func get_update_rate_ms() -> int:
		return self._update_rate_ms

	func get_last_update_ms() -> int:
		return self._last_update_ms

	func set_last_update_ms(ms: int) -> void:
		self._last_update_ms = ms

func example_callback_func(id: int, sem: Semaphore) -> void:	
	while true:
		sem.wait()
		print("This thread belongs to ID: ", id)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	data_A = DataThreadHandler.new()	
	data_A.init_data_thread_handler(1, 500, self.example_callback_func)

	data_B = DataThreadHandler.new()	
	data_B.init_data_thread_handler(2, 1000, self.example_callback_func)

func _process(delta: float) -> void:

	var curr_ms: int = Time.get_ticks_msec()

	if (curr_ms - self.data_A.get_last_update_ms() > self.data_A.get_update_rate_ms()):
		data_A.post_semaphore()
		data_A.set_last_update_ms(curr_ms)

	if (curr_ms - self.data_B.get_last_update_ms() > self.data_B.get_update_rate_ms()):
		data_B.post_semaphore()
		data_B.set_last_update_ms(curr_ms)
