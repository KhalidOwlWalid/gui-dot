class_name Guidot_Clock
extends Node

func _ready() -> void:
	self.name = Guidot_Utils.generate_unique_name(self, Guidot_Common._clock_group_name)
	self.add_to_group(Guidot_Common._clock_group_name)

func get_current_time_ms() -> int:
	return Time.get_ticks_msec()

func get_current_time_s() -> float:
	return float(Time.get_ticks_msec())/1000

func get_current_time_us() -> int:
	return Time.get_ticks_usec()
