extends Node

var counter := 0
var mutex: Mutex
var semaphore: Semaphore
var thread: Thread
var exit_thread := false


# The thread will start here.
func _ready():
	mutex = Mutex.new()
	semaphore = Semaphore.new()
	exit_thread = false

	thread = Thread.new()
	thread.start(_thread_function)

	print("Number of processor: ", OS.get_processor_count())

func _thread_function():
	while true:
		semaphore.wait() # Wait until posted.

		mutex.lock()
		var should_exit = exit_thread # Protect with Mutex.
		mutex.unlock()

		if should_exit:
			break

		mutex.lock()
		counter += 1 # Increment counter, protect with Mutex.
		mutex.unlock()


func increment_counter():
	semaphore.post() # Make the thread process.


func get_counter():
	mutex.lock()
	# Copy counter, protect with Mutex.
	var counter_value = counter
	mutex.unlock()
	return counter_value
