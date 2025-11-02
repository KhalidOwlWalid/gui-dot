extends Node

@onready var max_val: float = 100000000
@onready var v2_array: PackedVector2Array = PackedVector2Array()

func _ready() -> void:
	for i in range(0, max_val):
		v2_array.append(Vector2(i, 10))

func try_bsearch(vector: Vector2) -> void:
	print(v2_array.bsearch(vector))

func try_find(vector: Vector2) -> void:
	print(v2_array.find(vector))

func _process(delta: float) -> void:
	try_bsearch(Vector2(max_val, 10))
	try_find(Vector2(max_val, 10))
